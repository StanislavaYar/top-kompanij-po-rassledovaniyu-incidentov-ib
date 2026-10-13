#!/usr/bin/env bash
# Конвертация <_source>/screenshots/*.png -> assets/img/companies/*.webp (1200x750, без обрезки).
# Canvas в headless Chrome по file:// (нужен --allow-file-access-from-files), сервер не требуется.
set -euo pipefail
source "$(dirname "$0")/paths.sh"
cd "$SITE_DIR"
PAGE="file:///$(cygpath -m "$SITE_DIR/tools/gen/towebp.html")?src=file:///$(cygpath -m "$SOURCE_DIR/screenshots")"
"$CHROME" --headless=new --disable-gpu --allow-file-access-from-files --user-data-dir="$(cygpath -w /tmp/chrome-ir-gen)" \
  --virtual-time-budget=40000 --dump-dom "$PAGE" 2>/dev/null > "$SOURCE_DIR/gen/webp-dom.html"
perl -MMIME::Base64 -e 'local $/; my $d=<STDIN>; my $n=0; while($d=~/<pre id="out-([a-z0-9-]+)"[^>]*>data:image\/webp;base64,([^<]+)<\/pre>/g){ open my $o,">:raw","assets/img/companies/$1.webp" or die; print $o decode_base64($2); close $o; print "$1.webp\n"; $n++ } die "no images converted\n" unless $n;' < "$SOURCE_DIR/gen/webp-dom.html"
