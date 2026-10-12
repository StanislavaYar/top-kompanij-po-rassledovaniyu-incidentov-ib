#!/usr/bin/env bash
# Мобильный скриншот через iframe нужной ширины: bash tools/mshot.sh path label [width] [height]
# Нужен локальный сервер на docs/: powershell -ExecutionPolicy Bypass -File tools/serve.ps1 -Port 3100
source "$(dirname "$0")/paths.sh"
W="${3:-390}"; H="${4:-3000}"
bash "$SITE_DIR/tools/shot.sh" "file:///$(cygpath -m "$SITE_DIR/tools/gen/frame.html")?w=$W&h=$H&src=http://localhost:3100/$1" "$2" 520 "$H"
