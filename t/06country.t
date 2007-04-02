#!perl

use strict;
use Test::More;
use Act::Config;
use Act::Country;

# create a 'zz' language AUTO lexicon to catch missing translations
package Act::I18N::zz;
use base 'Act::I18N';
our %Lexicon = (_AUTO => 1);

package main;
$Config->set(general_default_language => 'zz');
$Request{language} = 'zz';
my $codes = Act::Country::CountryNames;

# get list of currently needed languages
my %languages;
for my $conf (keys %{$Config->conferences}) {
    my $cfg = Act::Config::get_config($conf);
    $languages{$_} = 1 for sort keys %{$cfg->languages};
}
my @languages = sort keys %languages;

plan tests => @languages * (1 + 4 * @$codes);

# This is broken w/ Test::Harness in current perls:
# binmode STDOUT, ':utf8';
# hence the encode_utf8() call
use Encode qw(encode_utf8);

for my $language (@languages) {
    $Request{language} = $language;
    my $c = Act::Country::CountryNames;
    isa_ok($c, 'ARRAY');
    for my $p (@$c) {
        isa_ok($p, 'HASH');
        my $ename = encode_utf8($p->{name});
        like( $p->{iso}, qr/^[a-z]{2}$/, "$ename iso $p->{iso}" );
        ok($p->{name} && $p->{name} ne "country_$p->{iso}", "$p->{iso} $ename $language");
        is(Act::Country::CountryName($p->{iso}), $p->{name}, "$p->{iso} $ename $language CountryName");
    }
}
