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

package Act::I18N::yy;
use base 'Act::I18N';
our %Lexicon = ( 'bar' => 'yyfoo' );

package Act::I18N::fr;
use base 'Act::I18N';
our %Lexicon = ( 'jour' => '[quant,_1,jour]',
                 'bail' => '[quant,_1,bail,baux]',
                 'flux' => '[quant,_1,flux,flux]',
               );

package Act::I18N::xx_xx;
use base 'Act::I18N';
our %Lexicon = ( 'bar' => 'xxbar' );

package main;
my @tests = (
 #  request  default  id     expected
 [ 'xx_XX',  'en',    'baz', 'xxfoo' ], # fallback to xx
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
 [ 'xx_XX',  'en',    'bar', 'xxbar' ],
);
my @tests_fr = (
 [ 'jour', 0, '0 jour',  'fr - 0 is singular' ],
 [ 'jour', 1, '1 jour',  'fr - 1 is singular' ],
 [ 'jour', 2, '2 jours', 'fr - 2 is plural'   ],
 [ 'flux', 0, '0 flux',  'fr - 0 is singular' ],
 [ 'flux', 1, '1 flux',  'fr - 1 is singular' ],
 [ 'flux', 2, '2 flux',  'fr - 2 is plural'   ],
 [ 'bail', 0, '0 bail',  'fr - 0 is singular' ],
 [ 'bail', 1, '1 bail',  'fr - 1 is singular' ],
 [ 'bail', 2, '2 baux',  'fr - 2 is plural'   ],
);
plan tests => 1 + 2 * @tests + @tests_fr;

require_ok('Act::I18N');

for my $t (@tests) {
    my ($lang, $default, $id, $expected) = @$t;
    $Request{language} = $lang;
    $Config->set(general_default_language => $default);

    my $lh = Act::I18N->get_handle($lang);
    ok($lh, "get_handle $lang");
    is($lh->maketext($id), $expected);
}
# language-specific tests
my $lh = Act::I18N->get_handle('fr');
for my $t (@tests_fr) {
    my ($key, $num, $expected, $desc) = @$t;
    is( $lh->maketext($key, $num), $expected, $desc );
}

__END__
