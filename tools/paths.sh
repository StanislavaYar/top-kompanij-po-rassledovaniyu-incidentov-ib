# Общие пути для скриптов (подключается через source).
# Папка сайта = корень проекта. Исходные PNG и рабочие скриншоты лежат вне нее:
#   <Рабочий стол>/_source/<имя папки сайта>/
SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$(cd "$SITE_DIR/.." && pwd)/_source/$(basename "$SITE_DIR")"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
mkdir -p "$SOURCE_DIR/screenshots" "$SOURCE_DIR/temporary-screenshots" "$SOURCE_DIR/gen"
