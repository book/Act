use strict;
use Act::Config;
use DBI;
use Test::More tests => 16;

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

require_ok('Act::Database');
for my $d (@databases) {
    my ($name, @c) = @$d;
    my $is_pg = $c[1] =~ /Pg:/ ? 1 : 0;

    my $dbh = DBI->connect(@c,
                            { AutoCommit => 0,
                              PrintError => 0,
                              pg_enable_utf8 => 1,
                            }
                          );

    if (not ok $dbh, "$name connect") {
        SKIP: {
            skip "connect failed; following tests can't be run", 4
        }
        next
    }

    SKIP: {
        skip "tests specific to PostgreSQL", 2 unless $is_pg;
        cmp_ok($dbh->{pg_server_version}, '>=', 80000, "$name server version");
        cmp_ok($dbh->{pg_lib_version}, '>=', 80000, "$name library version");
    }

    SKIP: {
        skip "irrelevent", 1 if $name eq 'wiki';
        my ($version, $required) = Act::Database::get_versions($dbh);
        is ($version, $required, "$name schema is up to date");
    }

    eval { $dbh->disconnect };
    is $@, "", "$name disconnect";
}

__END__
