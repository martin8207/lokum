#!/usr/bin/env python3
"""
Оптимизира всички снимки в mobile/assets/ - смалява резолюцията до разумен
максимум за мобилен екран и компресира JPEG-a, за да намали тежестта на
страницата при бавен мобилен интернет.

Употреба:
    python3 scripts/optimize-images.py

Изисква: pip install Pillow --break-system-packages
"""
import os
import sys
from PIL import Image

# Windows конзолата понякога е с cp1252 по подразбиране, което гърми на
# кирилица в print() - пусни hook-а (или скрипта) тихо и стабилно.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ASSETS_DIR = "mobile/assets"
MAX_DIM = 1080          # достатъчно за телефонен екран, дори при zoom
JPEG_QUALITY = 78        # добър баланс качество/размер за храна и продукти

def optimize_image(path):
    try:
        img = Image.open(path)
    except Exception as e:
        print(f"  SKIP (не е валидно изображение): {path} ({e})")
        return

    with open(path, "rb") as f:
        orig_bytes = f.read()
    orig_size = len(orig_bytes)
    w, h = img.size

    if max(w, h) > MAX_DIM:
        ratio = MAX_DIM / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

    # Реална прозрачност, не просто RGBA режим - много "PNG" файлове от
    # телефони/редактори имат алфа канал, който е 100% непрозрачен
    # (стойност 255 навсякъде). Такива компресират много по-добре като
    # JPEG, без никаква видима разлика.
    has_alpha = False
    if img.mode in ("RGBA", "LA", "PA"):
        has_alpha = img.getchannel("A").getextrema()[0] < 255
    elif "transparency" in img.info:
        has_alpha = True

    if has_alpha:
        # PNG с прозрачност (напр. изрязани снимки на бутилки) - пази се като
        # PNG, за да не изчезне прозрачния фон. `convert("RGB")` + JPEG щеше
        # тихо да го запълни с плътен цвят.
        img.convert("RGBA").save(path, "PNG", optimize=True)
    else:
        img.convert("RGB").save(path, "JPEG", quality=JPEG_QUALITY, optimize=True)
    new_size = os.path.getsize(path)

    if new_size >= orig_size:
        # Pillow-ският optimize=True понякога излиза по-слаб от външен
        # компресор (напр. PNG, вече смален през сайт за компресия) -
        # запазваме оригинала вместо да го "оптимизираме" до по-голям файл.
        with open(path, "wb") as f:
            f.write(orig_bytes)
        print(f"  {path}: {orig_size//1024}KB -> запазен оригинал (без подобрение)")
        return

    saved_pct = 100 * (1 - new_size / orig_size)
    print(f"  {path}: {orig_size//1024}KB -> {new_size//1024}KB (-{saved_pct:.0f}%)")


def main():
    count = 0
    for root, _, files in os.walk(ASSETS_DIR):
        for f in files:
            if f.lower().endswith((".jpg", ".jpeg", ".png")):
                optimize_image(os.path.join(root, f))
                count += 1
    print(f"\nГотово. Обработени {count} файла.")


if __name__ == "__main__":
    main()
