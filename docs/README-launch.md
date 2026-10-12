# Запуск сайта: этап 2 (открыть индексацию)

На первом этапе все страницы закрыты мета-тегом `<meta name="robots" content="noindex, nofollow">`.
`robots.txt` сайт не закрывает (`Allow: /`), иначе поисковики не увидят noindex.

## Как открыть индексацию

1. В `tools/build.pl` замените строку
   `my $ROBOTS    = 'noindex, nofollow';`
   на
   `my $ROBOTS    = 'index, follow';`
2. Пересоберите сайт: `bash build.sh`. Готовый сайт появится в папке `docs/`.
3. Проверьте, что в `<head>` каждой страницы стоит `index, follow`:
   `grep -L 'content="index, follow"' docs/index.html docs/*/index.html` должен вернуть пустой список.
   Страница `404.html` всегда остается `noindex, nofollow`.
4. Опубликуйте содержимое папки `docs/` и отправьте `sitemap.xml` в Яндекс Вебмастер и Google Search Console.

`robots.txt` на этапе 2 не меняется.
