use strict;
use Act::Config;
use DBI;
use Test::More tests => 4;

my $dbh = DBI->connect(
    $Config->database_dsn,
    $Config->database_user,
    $Config->database_passwd,
);
ok($dbh);
ok($dbh->disconnect);

SKIP: {
    skip "No test database defined", 2 unless $Config->database_test_dsn;
 
    my $dbh = DBI->connect(
            $Config->database_test_dsn,
            $Config->database_test_user,
            $Config->database_test_passwd,
    );
    ok($dbh);
    ok($dbh->disconnect);
}
__END__
