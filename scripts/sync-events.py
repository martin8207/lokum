#!/usr/bin/env python3
"""
Синхронизира mobile/assets/data/events.json:

1. Мести изтекли "upcoming" събития (с фиксирана дата, НЕ повтарящите се
   като Брънч/Викторина) в "past" - автоматично създава архивна папка
   assets/events/archive/<slug>_<ДДММГГГГ>/ и пренася постера/логото
   като корицова снимка там.
2. За ВСИЧКИ архивни събития (нови и стари) напасва "galleryImages"
   според файловете в съответната папка - очакван формат <slug>_1.jpg,
   <slug>_2.jpg и т.н. (номерата определят и реда). Няма нужда снимките
   да се добавят ръчно в JSON-а - просто ги пуснете в папката.
3. Регистрира новите архивни папки в mobile/pubspec.yaml (assets:), ако
   още не са там.

Употреба:
    python3 scripts/sync-events.py

Изисква: няма външни зависимости (само стандартна библиотека).
"""
import json
import os
import re
import shutil
import sys
from datetime import datetime

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

EVENTS_JSON = "mobile/assets/data/events.json"
ARCHIVE_DIR = "mobile/assets/events/archive"
ASSETS_ROOT = "mobile/assets"
PUBSPEC = "mobile/pubspec.yaml"


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return text.strip("_") or "event"


def archive_expired_events(data: dict) -> list[tuple[str, str]]:
    now = datetime.now()
    moved: list[tuple[str, str]] = []
    still_upcoming = []

    for event in data["upcoming"]:
        date_str = event.get("date")
        if not date_str:
            still_upcoming.append(event)
            continue
        try:
            event_date = datetime.fromisoformat(date_str)
        except ValueError:
            still_upcoming.append(event)
            continue
        if event_date >= now:
            still_upcoming.append(event)
            continue

        title = event.get("titleEn") or event.get("titleBg") or event["id"]
        folder_name = f"{slugify(title)}_{event_date.strftime('%d%m%Y')}"
        folder_path = os.path.join(ARCHIVE_DIR, folder_name)
        os.makedirs(folder_path, exist_ok=True)

        cover_rel = None
        poster = event.get("posterImage") or event.get("logoImage")
        if poster:
            src = os.path.join(ASSETS_ROOT, poster)
            if os.path.isfile(src):
                ext = os.path.splitext(src)[1]
                cover_rel = f"events/archive/{folder_name}/{folder_name}{ext}"
                dst = os.path.join(ASSETS_ROOT, cover_rel)
                if not os.path.isfile(dst):
                    shutil.copy2(src, dst)

        archived = {
            "id": folder_name,
            "titleBg": event.get("titleBg", ""),
            "titleEn": event.get("titleEn", ""),
            "date": date_str,
        }
        if cover_rel:
            archived["logoImage"] = cover_rel
        archived["galleryImages"] = []

        data["past"].append(archived)
        moved.append((event["id"], folder_name))

    data["upcoming"] = still_upcoming
    return moved


def sync_gallery_images(data: dict) -> int:
    updated = 0
    for event in data["past"]:
        logo = event.get("logoImage")
        if logo:
            folder = os.path.dirname(os.path.join(ASSETS_ROOT, logo))
            # Снимките се номерират по името на КОРИЦАТА (напр. корица
            # "DnD_VIT.jpeg" -> галерия "DnD_VIT_1.jpeg", "DnD_VIT_2.jpeg"),
            # не по името на папката - те често се различават по регистър/
            # изписване.
            cover_stem = os.path.splitext(os.path.basename(logo))[0]
        else:
            folder = os.path.join(ARCHIVE_DIR, event["id"])
            cover_stem = event["id"]
        if not os.path.isdir(folder):
            continue

        folder_slug = os.path.basename(folder)
        pattern = re.compile(
            rf"^{re.escape(cover_stem)}_(\d+)\.(jpe?g|png)$", re.IGNORECASE
        )
        numbered = []
        for fname in os.listdir(folder):
            m = pattern.match(fname)
            if m:
                numbered.append((int(m.group(1)), fname))
        numbered.sort()
        gallery = [
            f"events/archive/{folder_slug}/{fname}" for _, fname in numbered
        ]

        # Никога не изтривай снимки, които вече бяха зададени, ако сега не
        # намерим съвпадение (по-безопасно от изтичане на данни) - само
        # добавяме/обновяваме, когато РЕАЛНО открием файлове по шаблона.
        if gallery and gallery != event.get("galleryImages", []):
            event["galleryImages"] = gallery
            updated += 1
    return updated


def register_pubspec_assets(new_folders: list[str]) -> None:
    if not new_folders:
        return
    with open(PUBSPEC, encoding="utf-8") as f:
        lines = f.readlines()

    existing = "".join(lines)
    insert_at = None
    for i, line in enumerate(lines):
        if line.strip().startswith("- assets/events/archive/"):
            insert_at = i + 1
    if insert_at is None:
        # fallback: добави след "assets/events/quiz/"
        for i, line in enumerate(lines):
            if "assets/events/quiz/" in line:
                insert_at = i + 1
                break
    if insert_at is None:
        return

    to_add = []
    for folder in new_folders:
        entry = f"    - assets/events/archive/{folder}/\n"
        if entry not in existing:
            to_add.append(entry)

    if to_add:
        lines[insert_at:insert_at] = to_add
        with open(PUBSPEC, "w", encoding="utf-8") as f:
            f.writelines(lines)


def main():
    with open(EVENTS_JSON, encoding="utf-8") as f:
        data = json.load(f)

    moved = archive_expired_events(data)
    updated = sync_gallery_images(data)

    with open(EVENTS_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    register_pubspec_assets([folder for _, folder in moved])

    if moved:
        print(f"Преместени {len(moved)} изтекли събития в архива:")
        for old_id, folder in moved:
            print(f"  {old_id} -> archive/{folder}/")
    if updated:
        print(f"Обновени galleryImages за {updated} архивни събития.")
    if not moved and not updated:
        print("Няма промени - всичко е синхронизирано.")


if __name__ == "__main__":
    main()
