#!perl

use strict;
use Test::More qw(no_plan);
use DBI;
use Act::Config;
use Act::Country;

$Request{dbh} = DBI->connect(
    $Config->database_dsn,
    $Config->database_user,
    $Config->database_passwd,
);

my %t;
for my $language (sort keys %{$Config->languages}) {
    $Request{language} = $language;
    my $c = Act::Country::CountryNames;
    isa_ok($c, 'ARRAY');
    for my $p (@$c) {
        unless ($t{$p->{iso}}++) {
            isa_ok($p, 'HASH');
            like( $p->{iso}, qr/^[a-z]{2}$/, "$p->{name} iso" );
        }
        ok($p->{name}, "$p->{name} $language");
    }
}
