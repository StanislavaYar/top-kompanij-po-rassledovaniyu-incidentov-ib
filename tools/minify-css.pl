#!/usr/bin/perl
# Простая минификация CSS: удаляет комментарии и лишние пробелы.
# perl tools/minify-css.pl css/global.css > css/global.min.css
local $/;
my $css = <>;
$css =~ s{/\*.*?\*/}{}gs;
$css =~ s/\s+/ /g;
$css =~ s/\s*([{};:,>])\s*/$1/g;
$css =~ s/;}/}/g;
print $css;
