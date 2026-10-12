#!/usr/bin/env bash
# Сборка сайта: bash build.sh
# Источники: content/NN-*.md (контент), data/companies.json (карточки), assets/ (стили, шрифты, изображения), favicon и служебные файлы в корне.
# Результат: папка docs/ = готовый сайт. GitHub Pages публикует ветку main, папку /docs.
set -euo pipefail
cd "$(dirname "$0")"
PUBLIC="docs"
rm -rf "$PUBLIC"
mkdir -p "$PUBLIC"
PUBLIC_DIR="$PUBLIC" perl tools/build.pl
cp -r assets "$PUBLIC/"
cp favicon.svg favicon.ico apple-touch-icon.png icon-192.png icon-512.png site.webmanifest robots.txt README-launch.md .nojekyll "$PUBLIC/"
echo "Published files: $(find "$PUBLIC" -type f | wc -l), $(du -sh "$PUBLIC" | cut -f1)"
