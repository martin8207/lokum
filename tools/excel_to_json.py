"""
excel_to_json.py
-----------------
Конвертира database/excel/products_master.xlsx в mobile/assets/data/menu.json,
който Flutter приложението зарежда локално (bundled asset) чрез MenuService.

Използване:
    python tools/excel_to_json.py
    python tools/excel_to_json.py --input database/excel/products_master.xlsx --output mobile/assets/data/menu.json

Логика:
  - Всеки ред от excel-а е един продукт.
  - category/subcategory в изходния JSON се вземат ТОЧНО както са в excel-а –
    скриптът НЕ премества продукти между категории/подкатегории. Продукт с
    category="drinks" в excel-а остава под "drinks" в JSON-а, дори ако
    неговата subcategory обичайно се среща под друга категория.
  - Каноничната структура по-долу (взета от вашата схема на менюто) се
    ползва САМО за:
      1) българско/английско име на позната category/subcategory двойка;
      2) реда, в който категориите/подкатегориите се показват в менюто.
    Ако category/subcategory двойка от excel-а не съвпада с каноничната
    (напр. subcategory среща се под друга category в схемата), скриптът пак
    я запазва точно както е в excel-а, но отпечатва предупреждение, за да
    прецените дали е грешка в данните.
  - Ред без "category" в excel-а се маркира като "uncategorized" и се
    отпечатва предупреждение – не се познава автоматично.
  - Полето "image" в excel-а е празно за всички редове -> по конвенция от
    image__1_.png се генерира "<id>.webp" и се очаква снимката да се казва
    точно така в mobile/assets/images/products/.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------------------
# Канонична структура category -> subcategories, взета от вашата схема
# (Нещо за хапване / Коктейли / Напитки). Редът тук определя реда в менюто.
# ---------------------------------------------------------------------------
CANONICAL_TREE = [
    ("food", "Нещо за хапване", "Food", [
        ("brunch", "БРЪНЧ", "Brunch"),
        ("a_la_minute_dishes", "АЛАМИНУТИ", "A La Minute Dishes"),
        ("salads", "САЛАТИ", "Salads"),
        ("sandwiches", "САНДВИЧИ", "Sandwiches"),
        ("sauces", "СОСОВЕ", "Sauces"),
        ("nuts", "ЯДКИ", "Nuts"),
        ("desserts", "ДЕСЕРТИ", "Desserts"),
    ]),
    ("cocktails", "Коктейли", "Cocktails", [
        ("alcoholic_cocktails", "АЛКОХОЛНИ КОКТЕЙЛИ", "Alcoholic Cocktails"),
        ("non-alcoholic_cocktails_and_shakes", "БЕЗАЛКОХОЛНИ КОКТЕЙЛИ И ШЕЙКОВЕ", "Non-Alcoholic Cocktails And Shakes"),
        ("hot_cocktails", "ГОРЕЩИ КОКТЕЙЛИ", "Hot Cocktails"),
    ]),
    ("drinks", "Напитки", "Drinks", [
        ("invigorating_drinks", "ОБОДРЯВАЩИ", "Invigorating Drinks"),
        ("non-alcoholic", "БЕЗАЛКОХОЛНИ", "Non-Alcoholic"),
        ("alcoholic", "АЛКОХОЛНИ", "Alcoholic"),
        ("shots", "ШОТОВЕ", "Shots"),
        ("beer", "БИРА", "Beer"),
        ("wine", "ВИНО", "Wine"),
        ("other", "ДРУГИ", "Other"),
    ]),
]

CATEGORY_NAMES: dict[str, tuple[str, str]] = {
    cat_id: (cat_bg, cat_en) for cat_id, cat_bg, cat_en, _ in CANONICAL_TREE
}

# subcategory_id -> (category_id, subBg, subEn)
SUBCATEGORY_LOOKUP: dict[str, tuple[str, str, str]] = {}
for cat_id, _cat_bg, _cat_en, subs in CANONICAL_TREE:
    for sub_id, sub_bg, sub_en in subs:
        SUBCATEGORY_LOOKUP[sub_id] = (cat_id, sub_bg, sub_en)

# (category_id, subcategory_id) двойки, за които подкатегорията умишлено е
# под различна category от каноничната ѝ схема (напр. "other" под "food",
# не само под "drinks") – потвърдено от бара, не е грешка в excel-а, затова
# не се отпечатва предупреждение за тях.
ACCEPTED_CATEGORY_SUBCATEGORY_OVERRIDES: set[tuple[str, str]] = {
    ("food", "other"),
    ("cocktails", "shots"),
}

REQUIRED_COLUMNS = [
    "id", "category", "subcategory", "nameBg", "nameEn", "priceEur",
    "isNew", "isRecommended", "available",
]


def prettify(raw_id: str) -> str:
    """Fallback display name for an unrecognised category/subcategory id."""
    return raw_id.replace("_", " ").replace("-", " ").strip().title()


def split_list(value) -> list[str]:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return []
    if isinstance(value, bool):
        # Стойност True/False, попаднала по грешка в tags/allergens колона.
        return []
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return []
    return [part.strip() for part in text.split(",") if part.strip()]


def clean_str(value) -> str | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    text = str(value).strip()
    return text or None


def clean_float(value) -> float | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def clean_bool(value) -> bool:
    if isinstance(value, bool):
        return value
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return False
    if isinstance(value, (int, float)):
        # Excel-ски TRUE()/FALSE() формули идват през pandas като 1.0/0.0,
        # не като Python bool или текст "1" — трябва да се сравнят числово.
        return value != 0
    return str(value).strip().lower() in ("true", "1", "yes", "да", "x")


def build_menu(df: pd.DataFrame) -> tuple[dict, list[str]]:
    warnings: list[str] = []
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Липсват задължителни колони в excel-а: {missing}")

    # tree[category_id] = {"nameBg","nameEn","subs": {sub_id: {"nameBg","nameEn","products":[]}}}
    tree: dict[str, dict] = {}
    seen_unknown_subs: set[str] = set()
    row_count = 0
    skipped = 0

    for _, row in df.iterrows():
        product_id = clean_str(row.get("id"))
        if not product_id:
            skipped += 1
            continue
        row_count += 1

        raw_category = clean_str(row.get("category"))
        raw_subcategory = clean_str(row.get("subcategory")) or "other"

        # category/subcategory се вземат ТОЧНО от excel-а – не се местят.
        category_id = raw_category or "uncategorized"
        if not raw_category:
            warnings.append(
                f"Продукт '{product_id}': липсва category в excel-а -> сложен в 'uncategorized'."
            )

        canonical_names = CATEGORY_NAMES.get(category_id)
        cat_bg, cat_en = canonical_names if canonical_names else (prettify(category_id), prettify(category_id))

        canonical_sub = SUBCATEGORY_LOOKUP.get(raw_subcategory)
        if canonical_sub:
            canonical_parent, sub_bg, sub_en = canonical_sub
            if canonical_parent != category_id and (category_id, raw_subcategory) not in ACCEPTED_CATEGORY_SUBCATEGORY_OVERRIDES:
                # Просто информативно предупреждение – НЕ местим продукта.
                key = f"{category_id}/{raw_subcategory}"
                if key not in seen_unknown_subs:
                    seen_unknown_subs.add(key)
                    warnings.append(
                        f"Продукт '{product_id}': subcategory='{raw_subcategory}' обикновено е под "
                        f"category='{canonical_parent}' във вашата схема, но в excel-а е под "
                        f"category='{category_id}'. Оставено е както е в excel-а."
                    )
        else:
            sub_bg = sub_en = prettify(raw_subcategory)
            key = f"{category_id}/{raw_subcategory}"
            if key not in seen_unknown_subs:
                seen_unknown_subs.add(key)
                warnings.append(
                    f"Непознат subcategory '{raw_subcategory}' (продукт '{product_id}', "
                    f"category='{category_id}'). Няма BG/EN превод в схемата -> показва се "
                    f"като '{sub_bg}'. Ако не е нарочно, коригирайте excel-а."
                )

        image = clean_str(row.get("image")) or f"{product_id}.webp"

        allergens = split_list(row.get("allergens"))
        non_numeric_allergens = [a for a in allergens if not a.isdigit()]
        if non_numeric_allergens:
            warnings.append(
                f"Продукт '{product_id}': allergens='{allergens}' съдържа нечислови стойности "
                f"({non_numeric_allergens}) - изглежда tags и allergens колоните са разменени в excel-а."
            )

        product = {
            "id": product_id,
            "categoryId": category_id,
            "subcategoryId": raw_subcategory,
            "brand": clean_str(row.get("brand")),
            "variant": clean_str(row.get("variant")),
            "nameBg": clean_str(row.get("nameBg")) or product_id,
            "nameEn": clean_str(row.get("nameEn")) or product_id,
            "descriptionBg": clean_str(row.get("descriptionBg")),
            "descriptionEn": clean_str(row.get("descriptionEn")),
            "price": clean_float(row.get("priceEur")) or 0.0,
            "quantity": clean_float(row.get("quantity")),
            "unit": clean_str(row.get("unit")),
            "image": image,
            "featured": clean_bool(row.get("featured")),
            "isNew": clean_bool(row.get("isNew")),
            "isRecommended": clean_bool(row.get("isRecommended")),
            "available": clean_bool(row.get("available")),
            "tags": split_list(row.get("tags")),
            "allergens": allergens,
        }

        cat_node = tree.setdefault(category_id, {"nameBg": cat_bg, "nameEn": cat_en, "subs": {}})
        sub_node = cat_node["subs"].setdefault(raw_subcategory, {"nameBg": sub_bg, "nameEn": sub_en, "products": []})
        sub_node["products"].append(product)

    if skipped:
        warnings.append(f"Пропуснати {skipped} реда без 'id'.")

    # Подреждаме: първо каноничните категории/подкатегории в дефинирания ред,
    # после всичко останало (непознато), по азбучен ред.
    ordered_categories = []
    canonical_cat_order = [c[0] for c in CANONICAL_TREE]
    remaining_cat_ids = sorted(set(tree.keys()) - set(canonical_cat_order))
    for category_id in [*canonical_cat_order, *remaining_cat_ids]:
        if category_id not in tree:
            continue
        node = tree[category_id]
        canonical_sub_order = []
        for c_id, _b, _e, subs in CANONICAL_TREE:
            if c_id == category_id:
                canonical_sub_order = [s[0] for s in subs]
        remaining_sub_ids = sorted(set(node["subs"].keys()) - set(canonical_sub_order))
        sub_list = []
        for sub_id in [*canonical_sub_order, *remaining_sub_ids]:
            if sub_id not in node["subs"]:
                continue
            sub = node["subs"][sub_id]
            sub_list.append({
                "id": sub_id,
                "nameBg": sub["nameBg"],
                "nameEn": sub["nameEn"],
                "products": sub["products"],
            })
        ordered_categories.append({
            "id": category_id,
            "nameBg": node["nameBg"],
            "nameEn": node["nameEn"],
            "subcategories": sub_list,
        })

    menu = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "productCount": row_count,
        "categories": ordered_categories,
    }
    return menu, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input", default="database/excel/products_master.xlsx",
        help="Път до excel файла (по подразбиране database/excel/products_master.xlsx)",
    )
    parser.add_argument(
        "--output", default="mobile/assets/data/menu.json",
        help="Път до изходния JSON (по подразбиране mobile/assets/data/menu.json)",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        print(f"❌ Не намирам excel файла: {input_path}", file=sys.stderr)
        return 1

    df = pd.read_excel(input_path)
    menu, warnings = build_menu(df)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(menu, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"✅ Записани {menu['productCount']} продукта в {output_path}")
    print(f"✅ Категории: {[c['id'] for c in menu['categories']]}")

    if warnings:
        print(f"\n⚠️  {len(warnings)} предупреждения за данните в excel-а:")
        for w in warnings:
            print(f"   - {w}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
