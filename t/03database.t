use warnings;
use strict;
use Test::More;
use Test::Deep;
use Test::Exception;

use Test::MockObject;

require_ok('Act::Database');

my $required_version = Act::Database::required_version();
is($required_version, 12, "12 db upgrades found");

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift };
    my $dbh = Test::MockObject->new();
    $dbh->mock('selectrow_array' => sub { return undef });
    my @found = Act::Database::get_versions($dbh);
    cmp_deeply(\@found, [0, $required_version], "undef returns 0 as a version");
    is($warn, "No database schema version found.\n", ".. and correct warning found");
}

{
    my $dbh = Test::MockObject->new();
    $dbh->mock('selectrow_array' => sub { return 12 });
    my @found = Act::Database::get_versions($dbh);
    cmp_deeply(\@found, [12, $required_version], "12 returns 12");
}

{
    my $dbh = Test::MockObject->new();
    $dbh->mock('selectrow_array' => sub { die "Failure" });
    $dbh->mock('rollback' => sub { 1 });
    $dbh->mock('errstr' => sub { return "we dead" });
    throws_ok(
        sub {
            Act::Database::get_versions($dbh);
        },
        qr/Failed to retrieve the schema version/
    );
}

done_testing;

__END__
