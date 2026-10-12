#!/usr/bin/perl
# Ссылки на домены компаний рейтинга на главной: ожидается ровно 2 (таблица + "Сайт компании").
use strict; use warnings; use utf8; use JSON::PP;
binmode STDOUT, ':encoding(UTF-8)';
local $/;
open my $j, '<:encoding(UTF-8)', 'data/companies.json' or die; my $data = JSON::PP->new->decode(<$j>);
open my $f, '<:encoding(UTF-8)', ($ENV{PUBLIC_DIR} // "docs") . '/index.html' or die 'no docs/: run bash build.sh'; my $html = <$f>;
my @hrefs = $html =~ /href="(https?:\/\/[^"]+)"/g;
my $bad = 0;
for my $c (@{ $data->{companies} }) {
  my ($h) = $c->{url} =~ m{^https?://([^/]+)};
  my $host = join('.', (split /\./, $h)[-2, -1]);   # регистрируемый домен: учитываются и поддомены
  my $n = grep { m{^https?://(?:[^/]*\.)?\Q$host\E(?:/|$)} } @hrefs;
  printf "%-32s %-22s %d%s\n", $c->{name}, $host, $n, $n == 2 ? '' : '  <-- !';
  $bad++ if $n != 2;
}
print $bad ? "FAIL: $bad\n" : "OK: каждая компания = 2 ссылки\n";
