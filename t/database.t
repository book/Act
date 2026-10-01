# ABSTRACT: Unit tests for the database store
# ------------------------------------------------------------------------
# These tests assume that you have a local connection to your database
# configured.  If there's also a TCP/IP connection to the database
# available but not configured in act.ini, you can test this by
# setting the environment variable ACT_TEST_DATABASE_HOST to the name
# of the host running the database.

package main;

use Test::More;
use Test::Fatal;
use Test::MockObject;
use Test::MockModule;

use Act::Config ();

use_ok('Act::Store::Database');

sub mock_config {
    my %changes = @_;
    my $cfg = Test::MockObject->new;
    for my $field (qw(database_dsn database_host
                      database_user database_passwd)) {
        my $mock_field = $field =~ s/database_/database_test_/r;
        $cfg->set_always($field => exists $changes{$field} ?
                             $changes{$field} : $Act::Config::Config->$mock_field);
    }
    return $cfg;
}

my $current_schema_version;

# ======== Tests begin here ============================================
# Check straightforward creation of the singleton
{
    my $db = Act::Store::Database->instance;

    isa_ok($db->connector,'DBIx::Connector',
           'Correct class for the connector instanciated');
    $current_schema_version = $db->get_schema_version;
    cmp_ok($current_schema_version,'>',0,
           'We got a schema version from the database');

    my $same = Act::Store::Database->instance;
    is($db,$same,
       "The database store is a singleton");
}


# Check connection via TCP/IP, if configured
SKIP: {
    skip 'Environment variable ACT_TEST_DATABASE_HOST not set',2,
        unless $ENV{ACT_TEST_DATABASE_HOST};
    Act::Store::Database->_clear_instance;
    my $db;
    local $Act::Config::Config =
        mock_config(database_host => $ENV{ACT_TEST_DATABASE_HOST});
    is( exception { $db = Act::Store::Database->instance },
        undef,
        'Connection via TCP/IP established');
    is($db->get_schema_version,$current_schema_version,
       'Schema version same as for local connection');
}


# Check error handling: Code must die early and noisily if the
# database can not be connected, or of there is a mismatch between
# database and code schema versions
{
    Act::Store::Database->_clear_instance;
    local $Act::Config::Config =
        mock_config(database_user => 'misconfigured');

    like( exception { my $db = Act::Store::Database->instance },
          qr/Failed to retrieve the schema version/,
          "Bad database configuration is reported at startup"
      );
}
{
    Act::Store::Database->_clear_instance;
    my $mock = Test::MockModule->new('Act::Database');
    $mock->mock(required_version => sub { $current_schema_version + 1 });
    like( exception { my $db = Act::Store::Database->instance },
          qr/too old/,
          "Detect that a database update is required",
      );
}
{
    Act::Store::Database->_clear_instance;
    my $mock = Test::MockModule->new('Act::Database');
    $mock->mock(required_version => sub { $current_schema_version - 1 });
    like( exception { my $db = Act::Store::Database->instance },
          qr/too recent/,
          "Detect that the code can't handle that schema",
      );
}

Act::Store::Database->_clear_instance;

done_testing;
