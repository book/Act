use strict;
use Act::Config;
use DBI;
use Test::More tests => 2;

my $dbh = DBI->connect(
        $Config->database_dsn,
        $Config->database_user,
        $Config->database_passwd,
);
ok($dbh);
ok($dbh->disconnect);

__END__
