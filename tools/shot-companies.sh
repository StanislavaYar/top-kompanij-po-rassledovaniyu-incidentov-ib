#!/usr/bin/env bash
# Скриншоты первого экрана страниц услуг: bash tools/shot-companies.sh [slug ...]
# 1440x900 PNG в <_source>/screenshots/<slug>.png (вне папки сайта).
# При ошибке страницы услуги - повтор, затем главная сайта.
# Сайты с сертификатом российского корневого центра (ptsecurity.com, bdu.fstec.ru) на машине сборки
# не проходят проверку сертификата: для них снимок делается с --ignore-certificate-errors (только просмотр).
set -uo pipefail
source "$(dirname "$0")/paths.sh"
PROFILE="$(cygpath -w "${TMPDIR:-/tmp}/chrome-ir-shot")"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
OUT_DIR="$SOURCE_DIR/screenshots"
status() {
  local c; c="$(curl -s -o /dev/null -L -m 30 -A "$UA" -w '%{http_code}' "$1")"
  if [ "$c" = "000" ]; then c="$(curl -sk -o /dev/null -L -m 30 -A "$UA" -w '%{http_code}' "$1")"; [ "$c" != "000" ] && c="$c-cert"; fi
  echo "$c"
}
shoot() {
  local url="$1" out="$2" extra="$3"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-first-run --user-data-dir="$PROFILE" $extra \
    --user-agent="$UA" --lang=ru-RU --window-size=1440,900 --virtual-time-budget=12000 \
    --screenshot="$(cygpath -w "$out")" "$url" >/dev/null 2>&1
}
while IFS='|' read -r slug url fallback; do
  [ -z "$slug" ] && continue
  if [ $# -gt 0 ] && [[ " $* " != *" $slug "* ]]; then continue; fi
  target="$url"; code="$(status "$url")"
  if [[ "$code" != 200* ]]; then sleep 5; code="$(status "$url")"; fi
  if [[ "$code" != 200* ]] && [ -n "$fallback" ]; then
    echo "$slug: $url -> $code, fallback $fallback"; target="$fallback"; code="$(status "$fallback")"
  fi
  extra=""; [[ "$code" == *-cert ]] && extra="--ignore-certificate-errors"
  shoot "$target" "$OUT_DIR/$slug.png" "$extra"
  echo "$slug|$target|$code|$(date +%F)" | tee -a "$OUT_DIR/log.txt"
done <<'LIST'
paranoid-security|https://paranoid.security/|
f6|https://www.f6.ru/services/incident-response/|https://www.f6.ru/
solar|https://rt-solar.ru/services/jsoc/digital-forensic-and-incident-response/|https://rt-solar.ru/
bi-zone|https://bi.zone/catalog/services/incident-response/|https://bi.zone/
kaspersky|https://www.kaspersky.ru/small-to-medium-business-security/services/computer-incident-investigation|https://www.kaspersky.ru/
rtm-group|https://www.rtmtech.ru/services/rassledovanie-intsidentov-is|https://www.rtmtech.ru/
kredo-s|https://soc.credos.ru/uslugi/rassledovanie-intsidentov|https://soc.credos.ru/
positive-technologies|https://ptsecurity.com/services/incident-response/|https://www.ptsecurity.com/ru-ru/
ussc|https://sec.ussc.ru/services/incident-investigation|https://sec.ussc.ru/
bastion|https://bastion-tech.ru/services/incident-response|https://bastion-tech.ru/
LIST
