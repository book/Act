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
$Config->set(general_default_language => 'en');

my %t;
for my $language (qw(de en es fr it pt)) {
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
