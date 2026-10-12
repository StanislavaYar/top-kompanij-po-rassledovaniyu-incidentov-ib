#!/usr/bin/perl
# Объем карточек компаний в 01-glavnaya.md: видимые слова карточки (через пробел),
# у ссылок считается текст ссылки; заголовок H3, комментарии, URL и разделители таблиц не считаются.
use strict; use warnings; use utf8;
binmode STDOUT, ':encoding(UTF-8)';
open my $f, '<:encoding(UTF-8)', 'content/01-glavnaya.md' or die; local $/; my $t = <$f>; $t =~ s/\r//g;
my ($sec) = $t =~ /## Рейтинг: подробные карточки компаний\n(.*?)\n## /s;
my @cards = split /^### /m, $sec; shift @cards;
my ($min, $max) = (1e9, 0);
for my $c (@cards) {
  my ($h, $body) = split /\n/, $c, 2;
  $body =~ s/<!--.*?-->//gs;
  $body =~ s/\[([^\]]+)\]\([^)]+\)/$1/g;
  $body =~ s/^\|\s*-.*$//mg;
  $body =~ s/[|*]/ /g;
  my @w = split ' ', $body; my $n = scalar @w;
  $min = $n if $n < $min; $max = $n if $n > $max;
  printf "%-32s %d\n", $h, $n;
}
printf "min %d, max %d, spread %.1f%%\n", $min, $max, ($max - $min) / $min * 100;
