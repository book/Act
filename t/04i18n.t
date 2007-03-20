#!perl -w

use strict;
use Act::Config;

use Test::More;

# set up some test lexicons
package Act::I18N::en;
use base 'Act::I18N';
our %Lexicon = ( 'foo' => 'enfoo' );

package Act::I18N::xx;
use base 'Act::I18N';
our %Lexicon = ( 'baz' => 'xxfoo' );

# set up some test lexicons
package Act::I18N::yy;
use base 'Act::I18N';
our %Lexicon = ( 'bar' => 'yyfoo' );

package main;
my @tests = (
 #  request  default  id     expected
 [ 'yy',     'xx',    'bar', 'yyfoo' ],
 [ 'yy',     'xx',    'baz', 'xxfoo' ],
 [ 'yy',     'xx',    'foo', 'enfoo' ],
 [ 'yy',     'xx',    'qux', 'TRANSLATEME' ],
 [ 'xx',     'xx',    'foo', 'enfoo' ],
 [ 'xx',     'xx',    'qux', 'TRANSLATEME' ],
 [ 'xx',     'en',    'foo', 'enfoo' ],
 [ 'xx',     'en',    'qux', 'TRANSLATEME' ],
 [ 'en',     'en',    'foo', 'enfoo' ],
 [ 'en',     'en',    'qux', 'TRANSLATEME' ],
);
plan tests => 1 + 2 * scalar(@tests);

require_ok('Act::I18N');

for my $t (@tests) {
    my ($lang, $default, $id, $expected) = @$t;
    $Request{language} = $lang;
    $Config->set(general_default_language => $default);

    my $lh = Act::I18N->get_handle($lang);
    ok($lh, "get_handle $lang");
    is($lh->maketext($id), $expected);
}

__END__
