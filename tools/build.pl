#!/usr/bin/perl
# Сборка сайта из NN-*.md + data/companies.json -> */index.html, 404.html, sitemap.xml.
# Запуск из корня проекта: bash build.sh (или perl tools/build.pl)
# Комментарии <!-- --> в md = указания верстки: по ним выбирается компонент для следующего блока.
use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Path qw(make_path);
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

my $DOMAIN    = 'https://top-kompanij-po-rassledovaniyu-incidentov-ib.com';
my $DATE      = '2026-10-12';
my $DATE_RU   = '12.10.2026';
my $SITE_NAME = 'Рейтинг IR-компаний';
my $EDITORIAL = 'Редакция рейтинга';
my $EMAIL     = 'editor@top-kompanij-po-rassledovaniyu-incidentov-ib.com';
my $ROBOTS    = 'noindex, nofollow';
my $OG_IMAGE  = "$DOMAIN/assets/img/og/og-default.png";
my $PUBLIC    = $ENV{PUBLIC_DIR} // "docs";   # папка публикации (готовый сайт, GitHub Pages: main /docs)

# file, url path, nav key, layout (toc | page), schema type
my @PAGES = (
  ['content/01-glavnaya.md',                                 '',                                           'rating',  'toc',  'home'],
  ['content/02-metodologiya.md',                             'metodologiya/',                              'method',  'page', 'article'],
  ['content/03-dobavit-kompaniyu.md',                        'dobavit-kompaniyu/',                         '',        'page', 'webpage'],
  ['content/04-o-proekte.md',                                'o-proekte/',                                 'about',   'page', 'webpage'],
  ['content/05-redakcionnaya-politika.md',                   'redakcionnaya-politika/',                    '',        'page', 'webpage'],
  ['content/06-redakciya.md',                                'redakciya/',                                 '',        'page', 'editorial'],
  ['content/07-glossarij.md',                                'glossarij/',                                 '',        'page', 'glossary'],
  ['content/08-kontakty.md',                                 'kontakty/',                                  '',        'page', 'contact'],
  ['content/09-politika-konfidencialnosti.md',               'politika-konfidencialnosti/',                '',        'page', 'webpage'],
  ['content/10-kompyuternaya-kriminalistika.md',             'kompyuternaya-kriminalistika/',              'guides',  'toc',  'guide'],
  ['content/11-chto-delat-pri-incidente-ib.md',              'chto-delat-pri-incidente-ib/',               'guides',  'toc',  'guide'],
  ['content/12-utechka-personalnyh-dannyh-uvedomlenie-rkn.md', 'utechka-personalnyh-dannyh-uvedomlenie-rkn/', 'guides', 'toc', 'guide'],
  ['content/13-rassledovanie-krazhi-kriptovalyuty.md',       'rassledovanie-krazhi-kriptovalyuty/',        'guides',  'toc',  'guide'],
  ['content/14-404.md',                                      '404.html',                                   '',        'page', 'notfound'],
);

my @GUIDES = (
  ['kompyuternaya-kriminalistika/',               'Компьютерная криминалистика'],
  ['chto-delat-pri-incidente-ib/',                'Что делать при инциденте ИБ'],
  ['utechka-personalnyh-dannyh-uvedomlenie-rkn/', 'Утечка персональных данных: уведомление РКН'],
  ['rassledovanie-krazhi-kriptovalyuty/',         'Расследование кражи криптовалюты'],
);

# ---------- Data ----------
sub slurp { my ($f) = @_; open my $fh, '<:encoding(UTF-8)', $f or die "$f: $!"; local $/; my $s = <$fh>; close $fh; $s =~ s/\r//g; return $s; }
sub spew  { my ($f, $s) = @_; open my $fh, '>:encoding(UTF-8)', $f or die "$f: $!"; print $fh $s; close $fh; }

my $DATA = JSON::PP->new->utf8(0)->decode(slurp('data/companies.json'));
my %CO_BY_NAME = map { $_->{name} => $_ } @{ $DATA->{companies} };
my %CO_BY_SLUG = map { $_->{slug} => $_ } @{ $DATA->{companies} };

# ---------- Icons (Lucide, ISC) ----------
my %ICON = (
  'log-in'        => '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" x2="3" y1="12" y2="12"/>',
  'wrench'        => '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  'server'        => '<rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/>',
  'database'      => '<ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5V19A9 3 0 0 0 21 19V5"/><path d="M3 12A9 3 0 0 0 21 12"/>',
  'eye'           => '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  'clock'         => '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  'users'         => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  'shield'        => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
  'shield-alert'  => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="M12 8v4"/><path d="M12 16h.01"/>',
  'shield-check'  => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
  'file-text'     => '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>',
  'link'          => '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
  'refresh-cw'    => '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
  'globe'         => '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  'award'         => '<path d="m15.477 12.89 1.515 8.526a.5.5 0 0 1-.81.47l-3.58-2.687a1 1 0 0 0-1.197 0l-3.586 2.686a.5.5 0 0 1-.81-.469l1.514-8.526"/><circle cx="12" cy="8" r="6"/>',
  'scale'         => '<path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/>',
  'lock'          => '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  'wallet'        => '<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"/><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/>',
  'hard-drive'    => '<line x1="22" x2="2" y1="12" y2="12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/><line x1="6" x2="6.01" y1="16" y2="16"/><line x1="10" x2="10.01" y1="16" y2="16"/>',
  'cpu'           => '<rect width="16" height="16" x="4" y="4" rx="2"/><rect width="6" height="6" x="9" y="9" rx="1"/><path d="M15 2v2"/><path d="M15 20v2"/><path d="M2 15h2"/><path d="M2 9h2"/><path d="M20 15h2"/><path d="M20 9h2"/><path d="M9 2v2"/><path d="M9 20v2"/>',
  'network'       => '<rect x="16" y="16" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="9" y="2" width="6" height="6" rx="1"/><path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"/><path d="M12 12V8"/>',
  'mail'          => '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  'smartphone'    => '<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>',
  'cloud'         => '<path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/>',
  'user-x'        => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="17" x2="22" y1="8" y2="13"/><line x1="22" x2="17" y1="8" y2="13"/>',
  'search'        => '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  'check'         => '<path d="M20 6 9 17l-5-5"/>',
  'circle-check'  => '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
  'square-check'  => '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="m9 12 2 2 4-4"/>',
  'alert-triangle'=> '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
  'octagon-x'     => '<path d="m15 9-6 6"/><path d="M2.586 16.726A2 2 0 0 1 2 15.312V8.688a2 2 0 0 1 .586-1.414l4.688-4.688A2 2 0 0 1 8.688 2h6.624a2 2 0 0 1 1.414.586l4.688 4.688A2 2 0 0 1 22 8.688v6.624a2 2 0 0 1-.586 1.414l-4.688 4.688a2 2 0 0 1-1.414.586H8.688a2 2 0 0 1-1.414-.586z"/><path d="m9 9 6 6"/>',
  'x'             => '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  'menu'          => '<line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/>',
  'chevron-down'  => '<path d="m6 9 6 6 6-6"/>',
  'arrow-up'      => '<path d="m5 12 7-7 7 7"/><path d="M12 19V5"/>',
  'arrow-down'    => '<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>',
  'external-link' => '<path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h3"/>',
  'snowflake'     => '<line x1="2" x2="22" y1="12" y2="12"/><line x1="12" x2="12" y1="2" y2="22"/><path d="m20 16-4-4 4-4"/><path d="m4 8 4 4-4 4"/><path d="m16 4-4 4-4-4"/><path d="m8 20 4-4 4 4"/>',
  'key'           => '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4"/><path d="m21 2-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/>',
  'git-fork'      => '<circle cx="12" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><circle cx="18" cy="6" r="3"/><path d="M18 9v2c0 .6-.4 1-1 1H7c-.6 0-1-.4-1-1V9"/><path d="M12 12v3"/>',
  'ban'           => '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>',
  'map-pin'       => '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>',
  'zap'           => '<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>',
  'layers'        => '<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65"/><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',
  'calendar'      => '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>',
  'message-square'=> '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
  'plus-square'   => '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M8 12h8"/><path d="M12 8v8"/>',
  'target'        => '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>',
);
sub icon {
  my ($name, $cls) = @_;
  my $p = $ICON{$name} // die "no icon $name";
  $cls = $cls ? " $cls" : '';
  return qq{<svg class="ir-ico$cls" viewBox="0 0 24 24" aria-hidden="true" focusable="false">$p</svg>};
}
# Иконка по смыслу заголовка пункта
my @ICON_RULES = (
  [qr/вектор/i, 'log-in'], [qr/инструмент/i, 'wrench'], [qr/какие системы/i, 'server'], [qr/ущерб/i, 'database'],
  [qr/продолжается/i, 'eye'], [qr/когда началась/i, 'clock'], [qr/кто причаст/i, 'users'], [qr/почему атака/i, 'shield-alert'],
  [qr/официальн/i, 'globe'], [qr/ссылка у каждого|ссылка\./i, 'link'], [qr/^обновлени/i, 'refresh-cw'],
  [qr/проверяемост/i, 'shield-check'], [qr/^проверка/i, 'shield-check'], [qr/сравнимост/i, 'layers'], [qr/регулярност/i, 'calendar'],
  [qr/сбор данных/i, 'search'], [qr/лиценз/i, 'award'], [qr/срок реагирования/i, 'clock'], [qr/судебн/i, 'scale'],
  [qr/nda/i, 'lock'], [qr/профиль инцидента/i, 'target'],
  [qr/крипто/i, 'wallet'], [qr/глубина форензики/i, 'search'], [qr/скорость/i, 'zap'], [qr/юридическ/i, 'scale'],
  [qr/публичная/i, 'file-text'], [qr/прозрачност/i, 'eye'],
  [qr/диск/i, 'hard-drive'], [qr/оперативная/i, 'cpu'], [qr/сетевой/i, 'network'], [qr/журнал/i, 'file-text'],
  [qr/почтов/i, 'mail'], [qr/мобильн/i, 'smartphone'], [qr/облачн/i, 'cloud'],
  [qr/внешняя атака/i, 'globe'], [qr/инсайдер/i, 'user-x'], [qr/ошибка сотрудника/i, 'mail'], [qr/подрядчик/i, 'users'],
  [qr/число узлов/i, 'layers'], [qr/выезд/i, 'map-pin'], [qr/срочност/i, 'zap'],
  [qr/холодное/i, 'snowflake'], [qr/мультиподпис/i, 'key'], [qr/отзыв/i, 'ban'], [qr/разделение/i, 'git-fork'], [qr/изоляция/i, 'shield'],
  [qr/сообщить об ошибке/i, 'alert-triangle'], [qr/добавить компанию/i, 'plus-square'], [qr/вопрос по методолог/i, 'message-square'],
  [qr/таймлайн/i, 'clock'], [qr/закреплени/i, 'search'], [qr/ротация/i, 'key'], [qr/уведомлени/i, 'mail'],
  [qr/неопубликованн/i, 'eye'], [qr/качества/i, 'shield-alert'], [qr/формат данных/i, 'layers'],
);
sub icon_for { my ($t) = @_; for my $r (@ICON_RULES) { return $r->[1] if $t =~ $r->[0]; } return 'circle-check'; }

# ---------- Helpers ----------
my %TR = qw(а a б b в v г g д d е e ж zh з z и i й j к k л l м m н n о o п p р r с s т t у u ф f х h ц c ч ch ш sh щ shch ъ _ ы y ь _ э e ю yu я ya);
$TR{"\x{451}"} = 'e';
sub slugify {
  my ($t) = @_;
  $t = lc $t;
  $t =~ s/([а-я\x{451}])/$TR{$1}/g;
  $t =~ s/_//g;
  $t =~ s/[^a-z0-9]+/-/g;
  $t =~ s/^-+|-+$//g;
  $t = substr($t, 0, 60); $t =~ s/-+$//;
  return $t || 'sec';
}
sub esc { my ($s) = @_; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; return $s; }
sub attr { my ($s) = @_; $s = esc($s); $s =~ s/"/&quot;/g; return $s; }
sub plain {   # md -> чистый текст для JSON-LD и meta
  my ($s) = @_; $s =~ s/\*\*(.+?)\*\*/$1/g; $s =~ s/\[([^\]]+)\]\(([^)]+)\)/$1/g; $s =~ s/\s+/ /g; $s =~ s/^\s+|\s+$//g; return $s;
}
sub link_html {
  my ($text, $url) = @_;
  my $u = attr($url);
  if ($url =~ /^https?:/) { return qq{<a href="$u" target="_blank" rel="noopener">$text</a>}; }
  return qq{<a href="$u">$text</a>};
}
sub inl {
  my ($s) = @_;
  $s = esc($s);
  $s =~ s/\[([^\]]+)\]\(([^)\s]+)\)/link_html($1, $2)/ge;
  $s =~ s/\*\*(.+?)\*\*/<strong>$1<\/strong>/g;
  return $s;
}
sub na_class { my ($v) = @_; return ($v =~ /^не опубликовано$/) ? ' class="ir-na"' : ''; }

# ---------- Markdown parsing ----------
sub parse_md {
  my ($text) = @_;
  my @lines = split /\n/, $text;
  my (%meta, @blocks);
  # Шапка файла до первого "---": служебные поля
  my $i = 0;
  while ($i < @lines && $lines[$i] ne '---') {
    if ($lines[$i] =~ /^([A-Za-z ]+):\s*(.+)$/) { my ($k, $v) = ($1, $2); $v =~ s/^`|`$//g; $meta{lc $k} = $v; }
    $i++;
  }
  $i++;
  my @para;
  my $flush = sub { if (@para) { push @blocks, { t => 'p', lines => [@para] }; @para = (); } };
  while ($i < @lines) {
    my $l = $lines[$i];
    if ($l =~ /^\s*$/) { $flush->(); $i++; next; }
    if ($l =~ /^<!--\s*(.*?)\s*-->$/) { $flush->(); push @blocks, { t => 'c', text => $1 }; $i++; next; }
    if ($l =~ /^(#{1,3}) (.+)$/) { $flush->(); push @blocks, { t => 'h' . length($1), text => $2 }; $i++; next; }
    if ($l eq '---') { $flush->(); $i++; next; }
    if ($l =~ /^\|/) {
      $flush->(); my @rows;
      while ($i < @lines && $lines[$i] =~ /^\|/) {
        my $r = $lines[$i]; $r =~ s/^\|\s*|\s*\|$//g;
        my @cells = map { s/^\s+|\s+$//gr } split /\s*\|\s*/, $r, -1;
        push @rows, [@cells] unless $r =~ /^[-\s|]+$/;
        $i++;
      }
      my $head = shift @rows;
      push @blocks, { t => 'table', head => $head, rows => \@rows }; next;
    }
    if ($l =~ /^>/) {
      $flush->(); my @q;
      while ($i < @lines && $lines[$i] =~ /^>\s?(.*)$/) { push @q, $1; $i++; }
      my @paras; my @cur;
      for my $q (@q) { if ($q eq '') { push @paras, join(' ', @cur) if @cur; @cur = (); } else { push @cur, $q; } }
      push @paras, join(' ', @cur) if @cur;
      push @blocks, { t => 'quote', paras => \@paras }; next;
    }
    if ($l =~ /^- \[ \] (.+)$/) {
      $flush->(); my @it;
      while ($i < @lines && $lines[$i] =~ /^- \[ \] (.+)$/) { push @it, $1; $i++; }
      push @blocks, { t => 'todo', items => \@it }; next;
    }
    if ($l =~ /^- (.+)$/) {
      $flush->(); my @it;
      while ($i < @lines && $lines[$i] =~ /^- (.+)$/) { push @it, $1; $i++; }
      push @blocks, { t => 'ul', items => \@it }; next;
    }
    if ($l =~ /^\d+\. (.+)$/) {
      $flush->(); my @it;
      while ($i < @lines && $lines[$i] =~ /^\d+\. (.+)$/) { push @it, $1; $i++; }
      push @blocks, { t => 'ol', items => \@it }; next;
    }
    push @para, $l; $i++;
  }
  $flush->();
  return (\%meta, \@blocks);
}

# Разбор пункта "**Заголовок.** текст" -> (lead, rest)
sub split_lead {
  my ($item) = @_;
  if ($item =~ /^\*\*(.+?)\*\*\s*(.*)$/) { return ($1, $2); }
  return ('', $item);
}

# ---------- Components ----------
sub c_table {
  my ($b, %o) = @_;
  my $cls = 'ir-table' . ($o{cls} ? " $o{cls}" : '');
  my $label = $o{label} // plain(join(', ', @{ $b->{head} }));
  my $h = qq{<div class="ir-scroll@{[ $o{wrap} ? " $o{wrap}" : '' ]}" role="region" aria-label="@{[ attr($label) ]}" tabindex="0">\n<table class="$cls">\n};
  unless ($o{nohead}) {
    $h .= "<thead><tr>" . join('', map { '<th scope="col">' . inl($_) . '</th>' } @{ $b->{head} }) . "</tr></thead>\n";
  }
  $h .= "<tbody>\n";
  my @rows = @{ $b->{rows} };
  my $n = 0;
  for my $r (@rows) {
    $n++;
    my $rc = $o{rowclass} ? $o{rowclass}->($n, $r) : '';
    $h .= "<tr$rc>";
    for my $ci (0 .. $#$r) {
      my $v = $r->[$ci];
      my $cell = $o{cell} ? $o{cell}->($ci, $v, $r) : inl($v);
      my $dl = ($o{stack} && !$o{nohead}) ? ' data-label="' . attr(plain($b->{head}[$ci])) . '"' : '';
      my $na = ($v eq 'не опубликовано') ? ' class="ir-na"' : '';
      $h .= "<td$dl$na>$cell</td>";
    }
    $h .= "</tr>\n";
  }
  $h .= "</tbody>\n</table>\n</div>\n";
  return $h;
}

sub c_summary_table {
  my ($b) = @_;
  return c_table($b, cls => 'ir-rank', wrap => 'ir-scroll--rank', label => 'Сводная таблица ТОП-10 компаний',
    rowclass => sub { my ($n) = @_; return $n == 1 ? ' class="ir-row--nom"' : ''; },
    cell => sub {
      my ($ci, $v) = @_;
      if ($ci == 1) {
        my $co = $CO_BY_NAME{$v} or die "Нет компании в companies.json: $v";
        return link_html(esc($v), $co->{url});
      }
      return inl($v);
    });
}

sub c_weights {
  my ($b) = @_;
  my $max = 0;
  for my $r (@{ $b->{rows} }) { my ($w) = $r->[1] =~ /(\d+)/; $max = $w if $w > $max; }
  return c_table($b, cls => 'ir-table--weights', label => 'Критерии и веса',
    cell => sub {
      my ($ci, $v) = @_;
      if ($ci == 1 && $v =~ /(\d+)%/) {
        my $w = sprintf('%.0f', $1 / $max * 100);
        return qq{<span class="ir-weight"><span class="ir-weight__track"><span class="ir-weight__bar" style="--w:$w%"></span></span><span class="ir-weight__val">} . esc($v) . qq{</span></span>};
      }
      return inl($v);
    });
}

sub c_scale {
  my ($b) = @_;
  my $h = qq{<div class="ir-scale" role="group" aria-label="Порядок сбора доказательств">\n};
  $h .= '<p class="ir-scale__end">' . icon('arrow-up') . "Наиболее волатильные</p>\n<ol>\n";
  for my $r (@{ $b->{rows} }) {
    $h .= '<li><span class="ir-scale__bar" aria-hidden="true"></span><span class="ir-scale__n">' . esc($r->[0]) . '</span><span><span class="ir-scale__src">' . inl($r->[1]) . '</span><span class="ir-scale__what">' . inl($r->[2]) . "</span></span></li>\n";
  }
  $h .= "</ol>\n" . '<p class="ir-scale__end">' . icon('arrow-down') . "Наиболее устойчивые</p>\n</div>\n";
  return $h;
}

sub c_timeline {
  my ($b) = @_;
  my $h = qq{<ol class="ir-timeline" aria-label="@{[ attr(plain(join(' / ', @{ $b->{head} }))) ]}">\n};
  for my $r (@{ $b->{rows} }) {
    $h .= '<li><span class="ir-timeline__t">' . esc($r->[0]) . '</span><p>' . inl($r->[1]) . "</p></li>\n";
  }
  return "$h</ol>\n";
}

sub c_grid {
  my ($b, $cols, $variant) = @_;
  my $cls = "ir-grid ir-grid--$cols" . ($variant ? " ir-grid--$variant" : '');
  my $h = qq{<ul class="$cls">\n};
  for my $it (@{ $b->{items} }) {
    my ($lead, $rest) = split_lead($it);
    my $ic = icon(icon_for($lead));
    $h .= "<li>$ic<div><span class=\"ir-grid__lead\">" . inl($lead) . '</span>' . ($rest ne '' ? '<p>' . inl($rest) . '</p>' : '') . "</div></li>\n";
  }
  return "$h</ul>\n";
}

sub c_ilist {
  my ($b) = @_;
  my $h = qq{<ul class="ir-ilist">\n};
  for my $it (@{ $b->{items} }) {
    my ($lead) = split_lead($it);
    $h .= '<li>' . icon(icon_for($lead)) . '<span>' . inl($it) . "</span></li>\n";
  }
  return "$h</ul>\n";
}

sub c_process {
  my ($b) = @_;
  my $h = qq{<ol class="ir-process">\n};
  for my $it (@{ $b->{items} }) {
    my ($lead, $rest) = split_lead($it);
    $h .= '<li><span class="ir-process__t">' . inl($lead) . '</span><p>' . inl($rest) . "</p></li>\n";
  }
  return "$h</ol>\n";
}

sub c_steps {
  my ($b) = @_;
  my $h = qq{<ol class="ir-steps">\n};
  $h .= '<li>' . inl($_) . "</li>\n" for @{ $b->{items} };
  return "$h</ol>\n";
}

sub c_check {
  my ($b, $numbered) = @_;
  my $tag = $numbered ? 'ol' : 'ul';
  my $cls = $numbered ? 'ir-check ir-check--num' : 'ir-check';
  my $h = qq{<$tag class="$cls">\n};
  for my $it (@{ $b->{items} }) {
    $h .= '<li>' . ($numbered ? '' : icon($b->{t} eq 'todo' ? 'square-check' : 'circle-check')) . '<span>' . inl($it) . "</span></li>\n";
  }
  return "$h</$tag>\n";
}

sub c_list {
  my ($b) = @_;
  if ($b->{t} eq 'ol') { return qq{<ol class="ir-ol">\n} . join('', map { '<li>' . inl($_) . "</li>\n" } @{ $b->{items} }) . "</ol>\n"; }
  if ($b->{t} eq 'todo') { return c_check($b, 0); }
  return qq{<ul class="ir-list">\n} . join('', map { '<li>' . inl($_) . "</li>\n" } @{ $b->{items} }) . "</ul>\n";
}

sub c_quote {
  my ($b, $kind) = @_;
  $kind //= '';
  my $inner = join('', map { '<p>' . inl($_) . "</p>\n" } @{ $b->{paras} });
  return qq{<div class="ir-fact">\n$inner</div>\n} if $kind eq 'fact';
  my $cls = 'ir-callout' . ($kind ? " ir-callout--$kind" : '');
  return qq{<aside class="$cls">\n$inner</aside>\n};
}

sub c_para {
  my ($b, $cls) = @_;
  my $html = join("<br>\n", map { inl($_) } @{ $b->{lines} });
  return '<p' . ($cls ? qq{ class="$cls"} : '') . ">$html</p>\n";
}

sub c_tools_para {
  my ($b) = @_;
  my $html = join(' ', map { inl($_) } @{ $b->{lines} });
  my @tools = ('FTK Imager', 'Belkasoft RAM Capturer', 'Autopsy', 'The Sleuth Kit', 'SIFT Workstation', 'Timesketch', 'Volatility');
  for my $t (@tools) { $html =~ s/\Q$t\E/<span class="ir-chip">$t<\/span>/; }
  return "<p>$html</p>\n";
}

sub avatar {
  my ($size) = @_;
  my $cls = $size eq 'lg' ? 'ir-avatar ir-avatar--lg' : 'ir-avatar';
  return qq{<svg class="$cls" viewBox="0 0 64 64" role="img" aria-label="Редакция рейтинга"><rect width="64" height="64" rx="8" fill="#0B1F3A"/><rect x="14" y="14" width="36" height="36" rx="2" fill="none" stroke="#1E3A5F" stroke-width="2" transform="rotate(45 32 32)"/><g class="ir-avatar__turn"><rect x="19" y="19" width="26" height="26" rx="1.5" fill="none" stroke="#0EA5A4" stroke-width="2" stroke-dasharray="20 6"/></g><rect x="27" y="27" width="10" height="10" rx="1" fill="#0EA5A4" transform="rotate(45 32 32)"/><circle cx="32" cy="32" r="2" fill="#0B1F3A"/></svg>};
}

sub byline {
  my ($root, $with_method) = @_;
  my $h = qq{<div class="ir-byline">\n<div class="ir-byline__who">} . avatar('sm') .
    qq{<div><a class="ir-byline__name" href="${root}redakciya/">$EDITORIAL</a><br><span class="ir-byline__date">Обновлено: <time datetime="$DATE">$DATE_RU</time></span></div></div>\n};
  $h .= qq{<a class="ir-byline__method" href="${root}metodologiya/">Методология рейтинга</a>\n} if $with_method;
  return "$h</div>\n";
}

sub toc_list {
  my ($toc) = @_;
  return qq{<ol>\n} . join('', map { qq{<li><a href="#$_->[0]">} . esc($_->[1]) . "</a></li>\n" } @$toc) . "</ol>\n";
}

sub form_html {
  return <<"HTML";
<form class="ir-form" method="post" action="mailto:$EMAIL" enctype="text/plain">
<label><span>Название компании <span class="ir-req" aria-hidden="true">*</span></span><input type="text" name="company" required autocomplete="organization"></label>
<label><span>Сайт <span class="ir-req" aria-hidden="true">*</span></span><input type="url" name="site" required placeholder="https://"></label>
<label><span>Страница услуги <span class="ir-req" aria-hidden="true">*</span></span><input type="url" name="service_page" required placeholder="https://"></label>
<label><span>Email <span class="ir-req" aria-hidden="true">*</span></span><input type="email" name="email" required autocomplete="email"></label>
<label><span>Комментарий</span><textarea name="comment" rows="4"></textarea></label>
<button class="ir-btn" type="submit">Отправить заявку</button>
</form>
HTML
}

# Карточка компании из блоков H3-секции
sub c_card {
  my ($h3, $blocks, $root) = @_;
  my ($rank, $name) = $h3 =~ /^(\d+)\.\s+(.+)$/ or die "card h3: $h3";
  my $co = $CO_BY_NAME{$name} or die "card company: $name";
  my $slug = $co->{slug};
  my ($def, $attrs, $spec, $pros, $cons, $fit, $foot) = ('', '', '', '', '', '', '');
  my $mode = '';
  for my $b (@$blocks) {
    if ($b->{t} eq 'c') { next; }
    if ($b->{t} eq 'table') {
      $attrs = qq{<dl class="ir-attrs">\n};
      for my $r (@{ $b->{rows} }) { $attrs .= '<div><dt>' . esc($r->[0]) . '</dt><dd' . na_class($r->[1]) . '>' . inl($r->[1]) . "</dd></div>\n"; }
      $attrs .= "</dl>\n"; next;
    }
    if ($b->{t} eq 'ul') {
      my $ul = qq{<ul class="ir-list">\n} . join('', map { '<li>' . inl($_) . "</li>\n" } @{ $b->{items} }) . "</ul>\n";
      if ($mode eq 'pros') { $pros .= $ul } else { $cons .= $ul } next;
    }
    next unless $b->{t} eq 'p';
    my $txt = join("\n", @{ $b->{lines} });
    if ($txt =~ /^\*\*Специализация:\*\*\s*(.+?)\.?$/s) {
      my @tags = split /,\s*/, $1;
      $spec = qq{<p class="ir-card__spec"><strong>Специализация:</strong> } . join(' ', map { '<span class="ir-chip">' . esc($_) . '</span>' } @tags) . "</p>\n";
    } elsif ($txt eq '**Сильные стороны**') { $mode = 'pros'; $pros = qq{<p><strong>Сильные стороны</strong></p>\n};
    } elsif ($txt eq '**Ограничения**') { $mode = 'cons'; $cons = qq{<p><strong>Ограничения</strong></p>\n};
    } elsif ($txt =~ /^\*\*Кому подходит:\*\*/) { $fit = '<p class="ir-card__fit">' . inl($txt) . "</p>\n";
    } elsif ($txt =~ /^\[Сайт компании\]\(([^)]+)\)\nДанные: (.+)$/s) {
      my ($url, $data) = ($1, $2);
      $foot = qq{<div class="ir-card__foot">\n<p>Данные: } . inl($data) . "</p>\n" .
        qq{<a class="ir-btn ir-btn--ghost" href="@{[ attr($url) ]}" target="_blank" rel="noopener">Сайт компании } . icon('external-link') . "</a>\n</div>\n";
    } else { $def .= '<p class="ir-card__def">' . inl($txt) . "</p>\n"; }
  }
  my $badge = $co->{nomination} ? '<span class="ir-badge">' . icon('award') . esc($co->{nomination}) . '</span>' : '';
  my $img = "${root}assets/img/companies/$slug.webp";
  my $alt = "Сайт $name, скриншот от $DATE_RU";
  return <<"HTML";
<article class="ir-card" id="$slug">
<header class="ir-card__head"><h3><span class="ir-card__rank">$rank</span>@{[ esc($name) ]}</h3>$badge</header>
<div class="ir-card__top">
<figure class="ir-card__shot"><img src="$img" width="1200" height="750" alt="@{[ attr($alt) ]}" loading="lazy" decoding="async"></figure>
<div class="ir-card__lede">
$def</div>
</div>
<div class="ir-card__body">
$attrs$spec<div class="ir-card__pros"><div>
$pros</div><div>
$cons</div></div>
$fit</div>
$foot</article>
HTML
}

# ---------- Page body ----------
sub render_body {
  my ($meta, $blocks, $page) = @_;
  my ($file, $path, $nav, $layout, $kind) = @$page;
  my $root = $path eq '404.html' ? '/' : ($path eq '' ? '' : '../');
  my (@out, @toc, %ids, @faq);
  my $h1 = '';
  my $in_sec = 0;
  my $intro = 1;
  my $sec_title = '';
  my %state;
  my $uid = sub { my ($base) = @_; my $id = $base; my $n = 2; while ($ids{$id}) { $id = "$base-$n"; $n++; } $ids{$id} = 1; return $id; };
  my $close_sec = sub { if ($in_sec) { push @out, "</section>\n"; $in_sec = 0; } };
  my $first_para_done = 0;

  # Предварительный проход: H3 глоссария для алфавитного указателя
  my @letters;
  if ($kind eq 'glossary') {
    my %seen;
    for my $b (@$blocks) { next unless $b->{t} eq 'h3'; my $l = uc substr($b->{text}, 0, 1); next if $seen{$l}++; push @letters, [$l, slugify($b->{text})]; }
  }

  my $i = 0;
  while ($i < @$blocks) {
    my $b = $blocks->[$i];
    my $t = $b->{t};

    if ($t eq 'h1') {
      $h1 = $b->{text};
      push @out, '<h1>' . inl($h1) . "</h1>\n";
      $i++; next;
    }
    if ($t eq 'h2') {
      $close_sec->();
      if ($intro) { push @out, "</header>\n"; $intro = 0; }
      $sec_title = $b->{text};
      my $id = $uid->(slugify($sec_title));
      push @toc, [$id, plain($sec_title)];
      my $extra = $sec_title eq 'Источники' ? ' ir-sec--sources' : '';
      push @out, qq{<section class="ir-sec$extra" id="$id" aria-labelledby="$id-h">\n<h2 id="$id-h">} . inl($sec_title) . "</h2>\n";
      $in_sec = 1; %state = ();
      $state{faq} = 1 if $sec_title eq 'Частые вопросы';
      $i++; next;
    }
    if ($t eq 'h3') {
      if ($state{cards}) {
        my @cb; my $j = $i + 1;
        while ($j < @$blocks && $blocks->[$j]{t} !~ /^h[123]$/) { push @cb, $blocks->[$j]; $j++; }
        push @out, qq{<div class="ir-cards">\n} unless $state{cards_open}++;
        push @out, c_card($b->{text}, \@cb, $root);
        $ids{ $CO_BY_NAME{ ($b->{text} =~ /^\d+\.\s+(.+)$/)[0] }{slug} } = 1;
        $i = $j;
        if ($j >= @$blocks || $blocks->[$j]{t} ne 'h3') { push @out, "</div>\n"; $state{cards} = 0; }
        next;
      }
      my $id = $uid->(slugify($b->{text}));
      if ($kind eq 'glossary') {
        my $p = $blocks->[$i + 1];
        push @out, qq{<div class="ir-term" id="$id">\n<h3>} . inl($b->{text}) . "</h3>\n" . c_para($p) . "</div>\n";
        $i += 2; next;
      }
      push @out, qq{<h3 id="$id">} . inl($b->{text}) . "</h3>\n";
      $i++; next;
    }

    if ($t eq 'c') {
      my $c = $b->{text};
      my $next = $blocks->[$i + 1];
      if ($c =~ /^byline/) {
        push @out, byline($root, $kind eq 'home');
        push @out, "<!--TOC_INLINE-->
" if $layout eq "toc";
        if ($kind eq 'glossary') {
          push @out, qq{<nav aria-label="Алфавитный указатель"><ul class="ir-az">\n} . join('', map { qq{<li><a href="#$_->[1]">$_->[0]</a></li>} } @letters) . "\n</ul></nav>\n";
        }
        $i++; next;
      }
      if ($c =~ /^крупный анимированный/) { push @out, avatar('lg') . "\n"; $i++; next; }
      if ($c =~ /^алфавитный указатель/) { $i++; next; }
      if ($c =~ /^nomination-strip/) {
        my $p = join(' ', @{ $next->{lines} });
        $p =~ s/^\*\*(.+?):\*\*\s*(.+?)\.\s*\[(.+?)\]\((#[^)]+)\)$/<strong>$1:<\/strong> <span>$2.<\/span> <a href="$4">$3<\/a>/ or die "strip";
        push @out, qq{<p class="ir-strip">$p</p>\n};
        $i += 2; next;
      }
      if ($c =~ /^table: sticky header/) {
        push @out, c_summary_table($next);
        my $cap = $blocks->[$i + 2];
        if ($cap && $cap->{t} eq 'p') { push @out, c_para($cap, 'ir-caption'); $i += 3; } else { $i += 2; }
        next;
      }
      if ($c =~ /^mini-table/) { push @out, c_table($next, cls => 'ir-table--kv', nohead => 1, label => $sec_title); $i += 2; next; }
      if ($c =~ /^table: на mobile карточки/) { push @out, c_table($next, cls => 'ir-table--stack', wrap => 'ir-scroll--stack', stack => 1, label => $sec_title); $i += 2; next; }
      if ($c =~ /criteria-table|table с полосками/) { push @out, c_weights($next); $i += 2; next; }
      if ($c =~ /^volatility-scale/) { push @out, c_scale($next); $i += 2; next; }
      if ($c =~ /^timeline: /) { push @out, c_timeline($next); $i += 2; next; }
      if ($c =~ /^timeline-overview/) {
        my @heads = grep { $_->{t} eq 'h2' && $_->{text} =~ /^(Первые|До) \d+ час/ } @$blocks;
        my @labels = ('0-4 ч', '4-24 ч', '24-72 ч');
        my $h = qq{<ol class="ir-overview" aria-label="План по периодам">\n};
        for my $k (0 .. $#heads) { my $id = slugify($heads[$k]{text}); $h .= qq{<li><a href="#$id"><span class="ir-mono">$labels[$k]</span><span>} . esc($heads[$k]{text}) . "</span></a></li>\n"; }
        push @out, "$h</ol>\n"; $i++; next;
      }
      if ($c =~ /^process-diagram/) { push @out, c_process($next); $i += 2; next; }
      if ($c =~ /^steps 1-2-3/) { push @out, c_steps($next); $i += 2; next; }
      if ($c =~ /^grid 2x4|^icon-grid 2x2|^icon-grid 2x3/) { push @out, c_grid($next, 2); $i += 2; next; }
      if ($c =~ /^icon-grid 3x3|^icon-row|^icon-blocks|^principle-cards|^3 карточки/) { push @out, c_grid($next, 3); $i += 2; next; }
      if ($c =~ /^criteria-cards/) { push @out, c_grid($next, 2); $i += 2; next; }
      if ($c =~ /^icon-list/) { push @out, c_ilist($next); $i += 2; next; }
      if ($c =~ /^tag-list/) { push @out, c_tools_para($next); $i += 2; next; }
      if ($c =~ /^callout-note/) { push @out, c_quote($next, 'note'); $i += 2; next; }
      if ($c =~ /^formula-card/) { push @out, c_quote($next, 'formula'); $i += 2; next; }
      if ($c =~ /^fact-card amber/) { push @out, c_quote($next, 'fact'); $i += 2; next; }
      if ($c =~ /^callout-warning amber|^checklist amber/) {
        my $h = qq{<div class="ir-amber">\n};
        my $j = $i + 1;
        while ($j < @$blocks && $blocks->[$j]{t} =~ /^(ul|ol|quote)$/) {
          my $x = $blocks->[$j];
          if ($x->{t} eq 'quote') {
            $h .= qq{<div class="ir-amber__stop">} . icon('octagon-x') . '<div>' . join('', map { '<p>' . inl($_) . '</p>' } @{ $x->{paras} }) . "</div></div>\n";
          } else { $h .= c_check($x, $x->{t} eq 'ol'); }
          $j++;
        }
        push @out, "$h</div>\n"; $i = $j; next;
      }
      if ($c =~ /^callout/) { push @out, c_quote($next); $i += 2; next; }
      if ($c =~ /^checklist/) { push @out, c_check($next, $next->{t} eq 'ol'); $i += 2; next; }
      if ($c =~ /^two-column/) {
        my $h = qq{<div class="ir-cols2">\n}; my $j = $i + 1;
        while ($j + 1 < @$blocks && $blocks->[$j]{t} eq 'p' && $blocks->[$j + 1]{t} eq 'ul') {
          $h .= qq{<div class="ir-panel"><p class="ir-panel__title">} . inl(join(' ', @{ $blocks->[$j]{lines} })) . "</p>\n" . c_list($blocks->[$j + 1]) . "</div>\n";
          $j += 2;
        }
        push @out, "$h</div>\n"; $i = $j; next;
      }
      if ($c =~ /^form:/) { push @out, form_html(); $i++; next; }
      if ($c =~ /^10 карточек/) { $state{cards} = 1; $i++; next; }
      if ($c =~ /^FAQ/) { $state{faq} = 1; $i++; next; }
      $i++; next;   # прочие комментарии (указания без компонента) не выводятся
    }

    if ($t eq 'p') {
      my $txt = join("\n", @{ $b->{lines} });
      if ($state{faq} && $txt =~ /^\*\*(.+?)\*\*\n(.+)$/s) {
        my ($q, $a) = ($1, $2);
        push @out, qq{<div class="ir-faq">\n} unless $state{faq_open}++;
        push @out, '<details><summary><span>' . inl($q) . '</span>' . icon('chevron-down') . "</summary>\n<p>" . inl($a) . "</p></details>\n";
        push @faq, [plain($q), plain($a)];
        my $nb = $blocks->[$i + 1];
        if (!$nb || $nb->{t} ne 'p' || join("\n", @{ $nb->{lines} }) !~ /^\*\*.+?\*\*\n/) { push @out, "</div>\n"; }
        $i++; next;
      }
      my $cls = '';
      if ($intro && !$first_para_done && $h1) { $cls = 'ir-lead'; $first_para_done = 1; }
      $cls = 'ir-source' if $txt =~ /^Источники?: /;
      push @out, c_para($b, $cls);
      $i++; next;
    }
    if ($t eq 'table') { push @out, c_table($b, label => $sec_title); $i++; next; }
    if ($t eq 'quote') { push @out, c_quote($b); $i++; next; }
    if ($t =~ /^(ul|ol|todo)$/) {
      if ($sec_title eq 'Источники') { push @out, qq{<ol class="ir-sources">\n} . join('', map { '<li>' . inl($_) . "</li>\n" } @{ $b->{items} }) . "</ol>\n"; }
      else { push @out, c_list($b); }
      $i++; next;
    }
    $i++;
  }
  $close_sec->();
  if ($intro) { push @out, "</header>\n"; }
  my $body = qq{<header class="ir-intro">\n} . join('', @out);
  return ($body, \@toc, \@faq, $h1);
}

# ---------- Chrome ----------
sub header_html {
  my ($root, $nav) = @_;
  my $cur = sub { $_[0] eq $nav ? ' aria-current="page"' : '' };
  my $home = $root eq '' ? './' : $root;
  my $guides_li = join('', map { qq{<li><a href="$root$_->[0]">$_->[1]</a></li>} } @GUIDES);
  my $mark = logo_mark();
  my $ddcur = $nav eq 'guides' ? ' is-current' : '';
  return <<"HTML";
<a class="ir-skip" href="#main">Перейти к содержанию</a>
<header class="ir-header" role="banner">
<div class="ir-wrap ir-header__in">
<a class="ir-logo" href="$home">$mark<span>$SITE_NAME</span></a>
<nav class="ir-nav" role="navigation" aria-label="Основное меню">
<ul>
<li><a href="$home"@{[ $cur->('rating') ]}>Рейтинг</a></li>
<li><a href="${root}metodologiya/"@{[ $cur->('method') ]}>Методология</a></li>
<li><details class="ir-dd$ddcur"><summary>Гайды @{[ icon('chevron-down') ]}</summary><ul>$guides_li</ul></details></li>
<li><a href="${root}o-proekte/"@{[ $cur->('about') ]}>О проекте</a></li>
</ul>
</nav>
<details class="ir-mnav">
<summary aria-label="Открыть меню">@{[ icon('menu', 'ir-ico--menu') ]}@{[ icon('x', 'ir-ico--x') ]}</summary>
<nav class="ir-mnav__panel" aria-label="Меню">
<ul>
<li><a href="$home"@{[ $cur->('rating') ]}>Рейтинг</a></li>
<li><a href="${root}metodologiya/"@{[ $cur->('method') ]}>Методология</a></li>
<li><p class="ir-mnav__group">Гайды</p><ul>$guides_li</ul></li>
<li><a href="${root}o-proekte/"@{[ $cur->('about') ]}>О проекте</a></li>
</ul>
</nav>
</details>
</div>
</header>
HTML
}

sub logo_mark {
  return q{<svg viewBox="0 0 32 32" width="32" height="32" aria-hidden="true" focusable="false"><rect width="32" height="32" rx="6" fill="#0B1F3A"/><path d="M16 5.5 7.5 9v6.2c0 5.3 3.6 9.4 8.5 11.3 4.9-1.9 8.5-6 8.5-11.3V9Z" fill="none" stroke="#0EA5A4" stroke-width="2" stroke-linejoin="round"/><circle cx="15" cy="14.5" r="3.6" fill="none" stroke="#0EA5A4" stroke-width="2"/><path d="m17.7 17.2 3 3" stroke="#0EA5A4" stroke-width="2" stroke-linecap="round"/></svg>};
}

sub footer_html {
  my ($root) = @_;
  my $home = $root eq '' ? './' : $root;
  my $guides_li = join("\n", map { qq{<li><a href="$root$_->[0]">$_->[1]</a></li>} } @GUIDES);
  return <<"HTML";
<footer class="ir-footer" role="contentinfo">
<div class="ir-wrap">
<div class="ir-footer__cols">
<div>
<p class="ir-footer__title">Рейтинг</p>
<ul>
<li><a href="$home">Топ компаний по расследованию инцидентов ИБ</a></li>
<li><a href="${root}metodologiya/">Методология рейтинга</a></li>
</ul>
</div>
<div>
<p class="ir-footer__title">Гайды</p>
<ul>
$guides_li
</ul>
</div>
<div>
<p class="ir-footer__title">О проекте</p>
<ul>
<li><a href="${root}o-proekte/">О проекте</a></li>
<li><a href="${root}redakciya/">Редакция</a></li>
<li><a href="${root}redakcionnaya-politika/">Редакционная политика</a></li>
<li><a href="${root}glossarij/">Глоссарий</a></li>
</ul>
</div>
<div>
<p class="ir-footer__title">Связь</p>
<ul>
<li><a href="${root}kontakty/">Контакты</a></li>
<li><a href="${root}dobavit-kompaniyu/">Добавить компанию</a></li>
<li><a href="${root}politika-konfidencialnosti/">Политика конфиденциальности</a></li>
</ul>
<p class="ir-footer__note">Иконки: <a href="https://lucide.dev/license" target="_blank" rel="noopener">Lucide</a>, лицензия ISC. Шрифты: Inter и JetBrains Mono, лицензия <a href="${root}assets/fonts/OFL-LICENSE.txt">SIL Open Font License 1.1</a>.</p>
</div>
</div>
<div class="ir-footer__bottom">
<p>$SITE_NAME, 2026. Данные проверены $DATE_RU.</p>
<p>Логотипы и названия компаний являются товарными знаками их владельцев.</p>
</div>
</div>
</footer>
HTML
}

# ---------- JSON-LD ----------
my $PUB_ID = "$DOMAIN/#publisher";
my $ED_ID  = "$DOMAIN/#editorial";
sub site_nodes {
  return (
    { '@type' => 'Organization', '@id' => $PUB_ID, name => $SITE_NAME, url => "$DOMAIN/", email => $EMAIL,
      logo => { '@type' => 'ImageObject', url => "$DOMAIN/icon-512.png", width => 512, height => 512 } },
    { '@type' => 'WebSite', '@id' => "$DOMAIN/#website", name => $SITE_NAME, url => "$DOMAIN/", inLanguage => 'ru', publisher => { '@id' => $PUB_ID } },
    { '@type' => 'Organization', '@id' => $ED_ID, name => $EDITORIAL, url => "$DOMAIN/redakciya/", parentOrganization => { '@id' => $PUB_ID } },
  );
}
sub crumbs_list {
  my ($meta, $canonical) = @_;
  my @parts = split /\s*>\s*/, ($meta->{breadcrumbs} // '');
  return () unless @parts;
  my @items = ({ '@type' => 'ListItem', position => 1, name => 'Рейтинг', item => "$DOMAIN/" });
  my $last = $parts[-1];
  push @items, { '@type' => 'ListItem', position => 2, name => $last, item => $canonical };
  return { '@type' => 'BreadcrumbList', '@id' => "$canonical#breadcrumbs", itemListElement => \@items };
}

sub jsonld {
  my ($meta, $page, $canonical, $h1, $faq, $desc) = @_;
  my $kind = $page->[4];
  my @g = site_nodes();
  return @g if $kind eq 'notfound';
  my $art = {
    '@type' => 'Article', '@id' => "$canonical#article", headline => $h1, description => $desc,
    datePublished => $DATE, dateModified => $DATE, inLanguage => 'ru',
    author => { '@id' => $ED_ID }, publisher => { '@id' => $ED_ID },
    mainEntityOfPage => $canonical, image => $OG_IMAGE, isPartOf => { '@id' => "$DOMAIN/#website" },
  };
  my $webpage = sub { my ($type) = @_; return { '@type' => $type, '@id' => "$canonical#webpage", name => $meta->{title}, description => $desc, url => $canonical, inLanguage => 'ru', isPartOf => { '@id' => "$DOMAIN/#website" }, publisher => { '@id' => $PUB_ID }, dateModified => $DATE }; };
  if ($kind eq 'home') {
    push @g, $art;
    my $pos = 0;
    push @g, { '@type' => 'ItemList', '@id' => "$canonical#rating", name => 'Топ-10 компаний по расследованию инцидентов ИБ', numberOfItems => scalar @{ $DATA->{companies} }, itemListOrder => 'https://schema.org/ItemListOrderAscending',
      itemListElement => [ map { { '@type' => 'ListItem', position => $_->{rank}, name => $_->{name}, url => $_->{url} } } sort { $a->{rank} <=> $b->{rank} } @{ $DATA->{companies} } ] };
    push @g, { '@type' => 'BreadcrumbList', '@id' => "$canonical#breadcrumbs", itemListElement => [ { '@type' => 'ListItem', position => 1, name => 'Рейтинг', item => "$DOMAIN/" } ] };
  } elsif ($kind eq 'article' || $kind eq 'guide') {
    push @g, $art;
  } elsif ($kind eq 'contact') {
    push @g, $webpage->('ContactPage');
  } elsif ($kind eq 'editorial') {
    my $w = $webpage->('WebPage'); $w->{about} = { '@id' => $ED_ID }; push @g, $w;
  } elsif ($kind eq 'glossary') {
    my $w = $webpage->('WebPage'); $w->{mainEntity} = { '@id' => "$canonical#terms" }; push @g, $w;
  } else {
    push @g, $webpage->('WebPage');
  }
  push @g, crumbs_list($meta, $canonical) unless $kind eq 'home';
  if (@$faq && ($kind eq 'home' || $kind eq 'guide')) {
    push @g, { '@type' => 'FAQPage', '@id' => "$canonical#faq", mainEntity => [ map { { '@type' => 'Question', name => $_->[0], acceptedAnswer => { '@type' => 'Answer', text => $_->[1] } } } @$faq ] };
  }
  return @g;
}

# ---------- Build ----------
my @sitemap;
my $built = 0;
for my $page (@PAGES) {
  my ($file, $path, $nav, $layout, $kind) = @$page;
  my ($meta, $blocks) = parse_md(slurp($file));
  my $root = $path eq '404.html' ? '/' : ($path eq '' ? '' : '../');
  my ($body, $toc, $faq, $h1) = render_body($meta, $blocks, $page);
  my $title = $meta->{title} or die "$file: no Title";
  my $desc  = $meta->{description} // plain($h1);
  my $canonical = "$DOMAIN/$path";

  # Глоссарий: DefinedTermSet из H3
  my @extra;
  if ($kind eq 'glossary') {
    my @terms; my $k = 0;
    while ($k < @$blocks) { if ($blocks->[$k]{t} eq 'h3') { my $p = $blocks->[$k + 1]; push @terms, { '@type' => 'DefinedTerm', name => $blocks->[$k]{text}, description => plain(join(' ', @{ $p->{lines} })), url => "$canonical#" . slugify($blocks->[$k]{text}) }; } $k++; }
    push @extra, { '@type' => 'DefinedTermSet', '@id' => "$canonical#terms", name => plain($h1), hasDefinedTerm => \@terms };
  }
  my @graph = (jsonld($meta, $page, $canonical, plain($h1), $faq, $desc), @extra);
  my $ld = JSON::PP->new->utf8(0)->canonical(1)->pretty->encode({ '@context' => 'https://schema.org', '@graph' => \@graph });
  $ld =~ s{</}{<\\/}g;

  # Хлебные крошки
  my $crumbs = '';
  if ($meta->{breadcrumbs}) {
    my @parts = split /\s*>\s*/, $meta->{breadcrumbs};
    my $home = $root eq '' ? './' : $root;
    $crumbs = qq{<nav class="ir-crumbs" aria-label="Хлебные крошки"><ol>};
    for my $n (0 .. $#parts) {
      if ($n == 0) { $crumbs .= qq{<li><a href="$home">} . esc($parts[$n]) . '</a></li>'; }
      elsif ($n == $#parts) { $crumbs .= '<li aria-current="page">' . esc($parts[$n]) . '</li>'; }
      else { $crumbs .= '<li>' . esc($parts[$n]) . '</li>'; }
    }
    $crumbs .= "</ol></nav>\n";
  }

  my $main;
  if ($layout eq 'toc') {
    my $inline = qq{<details class="ir-toc-inline"><summary>Содержание } . icon('chevron-down') . qq{</summary><nav class="ir-toc" aria-label="Содержание страницы">} . toc_list($toc) . "</nav></details>\n";
    $body =~ s/<!--TOC_INLINE-->\n/$inline/;
    $main = qq{<div class="ir-wrap ir-layout">\n<aside class="ir-toc-side"><nav class="ir-toc" aria-label="Содержание">\n<p class="ir-toc__title">Содержание</p>\n} . toc_list($toc) . qq{</nav></aside>\n<article class="ir-article">\n$crumbs$body</article>\n</div>\n};
  } else {
    my $cls = $kind eq 'notfound' ? ' ir-404' : '';
    $main = qq{<div class="ir-wrap">\n<article class="ir-article ir-narrow$cls">\n$crumbs$body</article>\n</div>\n};
  }

  my $og_type = ($kind eq 'home' || $kind eq 'article' || $kind eq 'guide') ? 'article' : 'website';
  my $html = join('',
    "<!doctype html>\n<html lang=\"ru\">\n<head>\n",
    "<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
    '<title>' . esc($title) . "</title>\n",
    '<meta name="description" content="' . attr($desc) . "\">\n",
    '<meta name="robots" content="' . ($kind eq 'notfound' ? 'noindex, nofollow' : $ROBOTS) . "\">\n",
    "<link rel=\"canonical\" href=\"$canonical\">\n",
    "<meta property=\"og:type\" content=\"$og_type\">\n<meta property=\"og:locale\" content=\"ru_RU\">\n<meta property=\"og:site_name\" content=\"$SITE_NAME\">\n",
    '<meta property="og:title" content="' . attr($title) . "\">\n",
    '<meta property="og:description" content="' . attr($desc) . "\">\n",
    "<meta property=\"og:url\" content=\"$canonical\">\n<meta property=\"og:image\" content=\"$OG_IMAGE\">\n<meta property=\"og:image:width\" content=\"1200\">\n<meta property=\"og:image:height\" content=\"630\">\n",
    "<meta name=\"theme-color\" content=\"#0B1F3A\">\n",
    "<link rel=\"icon\" href=\"${root}favicon.ico\" sizes=\"32x32\">\n<link rel=\"icon\" href=\"${root}favicon.svg\" type=\"image/svg+xml\">\n<link rel=\"apple-touch-icon\" href=\"${root}apple-touch-icon.png\">\n<link rel=\"manifest\" href=\"${root}site.webmanifest\">\n",
    "<link rel=\"preload\" href=\"${root}assets/fonts/inter-cyrillic.woff2\" as=\"font\" type=\"font/woff2\" crossorigin>\n",
    "<link rel=\"stylesheet\" href=\"${root}assets/css/styles.css\">\n",
    "<script type=\"application/ld+json\">\n$ld</script>\n",
    "</head>\n<body>\n",
    header_html($root, $nav),
    "<main id=\"main\" class=\"ir-main\">\n$main</main>\n",
    footer_html($root),
    "<script src=\"${root}assets/js/ui.js\" defer></script>\n",
    "</body>\n</html>\n");

  my $out = $path eq '404.html' ? '404.html' : ($path eq '' ? 'index.html' : "${path}index.html");
  make_path("$PUBLIC/$path") if $path ne "" && $path ne "404.html";
  spew("$PUBLIC/$out", $html);
  push @sitemap, $canonical unless $kind eq 'notfound';
  $built++;
  printf "built %-55s title=%d desc=%d h2=%d faq=%d\n", $out, length($title), length($desc), scalar @$toc, scalar @$faq;
}

my $sm = qq{<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n};
$sm .= "  <url>\n    <loc>$_</loc>\n    <lastmod>$DATE</lastmod>\n  </url>\n" for @sitemap;
$sm .= "</urlset>\n";
spew("$PUBLIC/sitemap.xml", $sm);
print "Done: $built pages, sitemap.xml: " . scalar(@sitemap) . " URL\n";
