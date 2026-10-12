#!/usr/bin/perl
# Аудит папки сайта: какие файлы используются страницами, какие нет.
use strict; use warnings; use utf8; use File::Find; use File::Basename; use Cwd 'abs_path';
binmode STDOUT, ":encoding(UTF-8)";
chdir($ENV{PUBLIC_DIR} // "docs") or die "no docs/";
my %used;
my @allowed = qw(favicon.ico favicon.svg apple-touch-icon.png icon-192.png icon-512.png robots.txt sitemap.xml site.webmanifest README-launch.md .nojekyll 404.html index.html);
$used{$_} = 'служебный' for @allowed;
my @pages = ('index.html', glob('*/index.html'), '404.html');
sub mark { my ($from, $ref) = @_; $ref =~ s{^https://top-kompanij-po-rassledovaniyu-incidentov-ib\.com/}{/}; return if $ref =~ /^(https?:|mailto:|#|data:)/; $ref =~ s/[?#].*$//; return if $ref eq '';
  my $p = $ref =~ m{^/} ? substr($ref, 1) : dirname($from) . "/$ref"; $p =~ s{^\./}{}; 1 while $p =~ s{[^/]+/\.\./}{}; $p .= 'index.html' if $p =~ m{/$} || $p eq '';
  $p = "$p/index.html" if -d $p; $used{$p} ||= $from; }
for my $f (@pages) { open my $h, '<:encoding(UTF-8)', $f or die; local $/; my $s = <$h>; $used{$f} = 'страница';
  mark($f, $1) while $s =~ /(?:href|src|content)="([^"]+)"/g; }
for my $css (grep { $used{$_} } glob('assets/css/*.css')) { open my $h, '<', $css; local $/; my $s = <$h>; mark($css, $1) while $s =~ /url\("?([^")]+)"?\)/g; }
open my $m, '<', 'site.webmanifest'; { local $/; my $s = <$m>; mark('site.webmanifest', $1) while $s =~ /"src":\s*"([^"]+)"/g; }
my (@site, @other, $size);
find({ no_chdir => 1, wanted => sub { return unless -f; my $p = $File::Find::name; $p =~ s{^\./}{}; 
  if ($used{$p}) { push @site, $p; $size += -s $p } else { push @other, $p } } }, '.');
print "== Файлы сайта (используются страницами или служебные): " . scalar(@site) . sprintf(", %.2f МБ\n", $size / 1048576);
printf "%8.1f КБ  %s\n", (-s $_) / 1024, $_ for sort @site;
print "\n== Файлы без ссылок со страниц: " . scalar(@other) . "\n";
my %grp; for (@other) { my ($top) = m{^([^/]+)}; push @{ $grp{$top} }, $_ }
for my $g (sort keys %grp) { printf "  %-55s %d файл(ов)\n", $g . (@{ $grp{$g} } > 1 || $grp{$g}[0] ne $g ? '/' : ''), scalar @{ $grp{$g} } }
my @png = grep { /\.png$/i } @other; print "\nPNG без ссылок: " . (@png ? join(', ', @png) : 'нет') . "\n";
