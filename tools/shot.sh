#!/usr/bin/env bash
# Скриншот через headless Chrome: bash tools/shot.sh URL label [width] [height]
# Сохраняет в <_source>/temporary-screenshots/screenshot-N-label.png (вне папки сайта)
set -euo pipefail
source "$(dirname "$0")/paths.sh"
URL="$1"; LABEL="${2:-shot}"; W="${3:-1440}"; H="${4:-900}"
DIR="$SOURCE_DIR/temporary-screenshots"
N=1; while ls "$DIR"/screenshot-$N-*.png >/dev/null 2>&1; do N=$((N+1)); done
OUT="$DIR/screenshot-$N-$LABEL.png"
PROFILE="$(cygpath -w "${TMPDIR:-/tmp}/chrome-shot-profile")"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-first-run --user-data-dir="$PROFILE" \
  --window-size="$W,$H" --virtual-time-budget=4000 --screenshot="$(cygpath -w "$OUT")" "$URL" >/dev/null 2>&1 || true
echo "$OUT"
