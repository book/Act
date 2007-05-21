use strict;
use Act::Config;
use DBI;
use Test::More;

my @databases = (
    [ 'main',
      $Config->database_dsn,
      $Config->database_user,
      $Config->database_passwd,
    ],
    [ 'test',
      $Config->database_test_dsn,
      $Config->database_test_user,
      $Config->database_test_passwd,
    ],
    [ 'wiki',
      'dbi:Pg:dbname=' . $Config->wiki_dbname,
      $Config->wiki_dbuser,
      $Config->wiki_dbpass,
    ],
);

plan tests => 4 * @databases;

for my $d (@databases) {
    my ($name, @c) = @$d;
    my $dbh = DBI->connect(@c);
    ok($dbh, "$name connect");
    cmp_ok($dbh->{pg_server_version}, '>=', 80000, "$name server version");
    cmp_ok($dbh->{pg_lib_version}, '>=', 80000, "$name library version");
    ok($dbh->disconnect, "$name disconnect");
}

__END__
