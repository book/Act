use strict;
use Test::More tests => 3;
use t::Util;
use Act::Util;

# manually insert some translations
my @t = (
 [ 'ta', 'co', 1, 'en', 'foo' ],
 [ 'ta', 'co', 1, 'fr', 'bar' ],
 [ 'ta', 'co', 2, 'en', 'baz' ],
);

my $sth = $Request{dbh}->prepare_cached('INSERT INTO translations (tbl,col,id,lang,text) VALUES(?,?,?,?,?)');
$sth->execute(@$_) for @t;

$Request{language} = 'en'; is(Act::Util::get_translation('ta', 'co', 1), 'foo', 'en');
$Request{language} = 'fr'; is(Act::Util::get_translation('ta', 'co', 1), 'bar', 'fr');
$Request{language} = 'en'; is(Act::Util::get_translation('ta', 'co', 2), 'baz', 'default');
