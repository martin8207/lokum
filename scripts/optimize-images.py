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
from PIL import Image

ASSETS_DIR = "mobile/assets"
MAX_DIM = 1080          # достатъчно за телефонен екран, дори при zoom
JPEG_QUALITY = 78        # добър баланс качество/размер за храна и продукти

def optimize_image(path):
    try:
        img = Image.open(path)
    except Exception as e:
        print(f"  SKIP (не е валидно изображение): {path} ({e})")
        return

    orig_size = os.path.getsize(path)
    w, h = img.size

    if max(w, h) > MAX_DIM:
        ratio = MAX_DIM / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

    img.convert("RGB").save(path, "JPEG", quality=JPEG_QUALITY, optimize=True)
    new_size = os.path.getsize(path)

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
