#!/bin/bash
# Еднократен setup - пуска се веднъж след clone на repo-то, за да активира
# споделените git hooks (напр. автоматична оптимизация на снимки при commit).
#
# Употреба: bash scripts/setup.sh

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit

echo "Git hooks активирани (.githooks/). Оттук нататък снимките ще се оптимизират автоматично при всеки commit."
