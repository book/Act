#!perl

use strict;
use Act::Config;
use Act::Country;
use Test::More qw(no_plan);

for my $p (@Act::Country::Countries) {
    isa_ok($p, 'HASH');
    like( $p->{iso}, qr/^[a-z]{2}$/, "$p->{fr} iso" );
    for my $language (sort keys %{$Config->languages}) {
       ok($p->{$language}, "$p->{fr} $language");
    }
}
