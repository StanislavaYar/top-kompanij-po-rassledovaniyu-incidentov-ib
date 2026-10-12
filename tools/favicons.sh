#!/usr/bin/env bash
# Растеризация favicon.svg -> apple-touch-icon.png, icon-192.png, icon-512.png, favicon.ico; OG-картинка.
# Промежуточный PNG 32x32 для ICO пишется в <_source>/gen/ (вне папки сайта).
set -euo pipefail
source "$(dirname "$0")/paths.sh"
cd "$SITE_DIR"
P="$(cygpath -w /tmp/chrome-ir-gen)"
shot() { "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-device-scale-factor=1 --user-data-dir="$P" \
  --window-size="$2,$3" --virtual-time-budget=3000 --screenshot="$(cygpath -w "$4")" "$1" >/dev/null 2>&1; }
ICON="file:///$(cygpath -m "$SITE_DIR/tools/gen/icon.html")"
shot "$ICON?s=180" 180 180 apple-touch-icon.png
shot "$ICON?s=192" 192 192 icon-192.png
shot "$ICON?s=512" 512 512 icon-512.png
shot "$ICON?s=32" 32 32 "$SOURCE_DIR/gen/fav32.png"
shot "file:///$(cygpath -m "$SITE_DIR/tools/gen/og.html")" 1200 630 assets/img/og/og-default.png
# favicon.ico = ICO-контейнер с одним PNG 32x32
perl -e 'local $/; open my $f,"<:raw",$ARGV[0] or die; my $p=<$f>; open my $o,">:raw","favicon.ico"; print $o pack("vvv",0,1,1).pack("CCCCvvVV",32,32,0,0,1,32,length($p),22).$p;' "$SOURCE_DIR/gen/fav32.png"
echo "icons done"
