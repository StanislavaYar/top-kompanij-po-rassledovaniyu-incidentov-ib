#!/usr/bin/perl
# Проверки сборки: JSON-LD, внутренние ссылки, alt, объем карточек, внешние ссылки (список в /tmp/ext-links.txt)
use strict; use warnings; use utf8; use JSON::PP; use File::Spec; use File::Basename;
chdir($ENV{PUBLIC_DIR} // "docs") or die "no docs/: run bash build.sh";
binmode STDOUT, ':encoding(UTF-8)';
my @files = ('index.html', glob('*/index.html'), '404.html');
my (%ext, $err);
for my $f (@files) {
  open my $fh, '<:encoding(UTF-8)', $f or die; local $/; my $h = <$fh>; close $fh;
  while ($h =~ m{<script type="application/ld\+json">\n(.*?)</script>}gs) {
    my $j = $1; $j =~ s{<\/}{</}g;
    my $d = eval { JSON::PP->new->decode($j) }; if (!$d) { print "BAD JSON-LD $f: $@\n"; $err++; next; }
    my @types = map { $_->{'@type'} } @{ $d->{'@graph'} }; print "$f: @types\n";
  }
  my $dir = dirname($f);
  while ($h =~ /(?:href|src)="([^"]+)"/g) {
    my $u = $1;
    if ($u =~ /^https?:/) { $ext{$u}++ unless $u =~ /^https:\/\/top-kompanij/; next; }
    next if $u =~ /^(mailto:|#)/;
    my $p = $u; $p =~ s/#.*$//; next if $p eq '';
    my $path = $p =~ m{^/} ? ".$p" : "$dir/$p";
    $path .= 'index.html' if $path =~ m{/$};
    $path = "$path/index.html" if -d $path;
    unless (-e $path) { print "BROKEN $f -> $u\n"; $err++; }
  }
  while ($h =~ /<img\b([^>]*)>/g) { my $a = $1; print "NO ALT $f\n" unless $a =~ /alt="[^"]+"/; }
  if ($f eq 'index.html') {
    while ($h =~ m{<article class="ir-card" id="([^"]+)">(.*?)</article>}gs) {
      my ($id, $c) = ($1, $2);
      my $ext = () = $c =~ /target="_blank"/g;
      $c =~ s/<[^>]+>/ /g; $c =~ s/&\w+;/ /g;
      my @w = grep { /[\p{L}\p{N}]/ } split /\s+/, $c;
      printf "card %-24s words=%d ext_links=%d\n", $id, scalar @w, $ext;
    }
  }
}
open my $o, '>', '/tmp/ext-links.txt'; print $o "$_\n" for sort keys %ext; close $o;
print "external links: " . scalar(keys %ext) . "\n";
print $err ? "ERRORS: $err\n" : "OK\n";
