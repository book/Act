use strict;
use Test::More tests => 5;
use t::Util;
use Act::Util;

# manually insert some translations
my @t = (
 [ 'ta', 'co', 1, 'en', 'foo' ],
 [ 'ta', 'co', 1, 'fr', 'bar' ],
 [ 'ta', 'co', 2, 'fr', 'baz' ],
);
$Config->set(general_default_language => 'fr');
$Config->set(general_languages => { map { $_ => 1 } qw(en fr) });

my $sth = $Request{dbh}->prepare_cached('INSERT INTO translations (tbl,col,id,lang,text) VALUES(?,?,?,?,?)');
$sth->execute(@$_) for @t;

$Request{language} = 'en'; is(Act::Util::get_translation('ta', 'co', 1), 'foo', 'get_translation en');
$Request{language} = 'fr'; is(Act::Util::get_translation('ta', 'co', 1), 'bar', 'get_translation fr');
$Request{language} = 'en'; is(Act::Util::get_translation('ta', 'co', 2), 'baz', 'get_translation default');

$Request{language} = 'fr';
is_deeply(Act::Util::get_translations('ta', 'co'), { 1 => 'bar', 2 => 'baz' }, 'get_translations fr');
$Request{language} = 'en';
is_deeply(Act::Util::get_translations('ta', 'co'), { 1 => 'foo', 2 => 'baz' }, 'get_translations en');
