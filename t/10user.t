use Test::More tests => 11;
use Act::User;
use t::Util;   # load the test database

my ($user, $user2);

# empty user
$user = Act::User->new;
isa_ok( $user, 'Act::User' );
is_deeply( $user, {}, "Empty new user" );

# manually insert a user and fetch it
my $sth = $Request{dbh}->prepare_cached("INSERT INTO users (login,passwd,email,country, first_name, last_name) VALUES(?,?,?,?,?,?);");
$sth->execute( 'test', 't3st', 'foo@bar.com', 'fr', 'first', 'last' );
$sth->finish();

$user = Act::User->new( login => 'test' );
isa_ok( $user, 'Act::User' );

# create a new user
$user = Act::User->create(
    login   => 'test2',
    passwd  => 't3st',
    email   => 'bar@bar.com',
    country => 'en',
    first_name => 'Foo',
    last_name => 'bar',
    nick_name => 'baz',
    pseudonymous => 't',
);
isa_ok( $user, 'Act::User' );
is( $user->login, 'test2', "check accessor" );

# check the Act::User::fields hash
my %h = %{ $user };
@h{keys %h} = ( 1 ) x keys %h;
is_deeply( \%h, \%Act::User::fields, "All the fields are here" );

# ENOSUCHUSER
$user = Act::User->new( login => 'foo' );
is( $user, undef, "User foo not found" );

# fetch a user
$user = Act::User->new( login => 'test' );
isa_ok( $user, 'Act::User' );

$user2 = Act::User->new( user_id => $user->user_id );
is_deeply( $user, $user2, "Same data from login or user_id" );

# fetch a user by name
$user = Act::User->new( login => 'test' );
is_deeply( Act::User->get_users( name => 'last' ), [ $user ], "Found a user by name" );

# fecth a pseudonymous user by nick_name
$user = Act::User->new( login => 'test2' );
is_deeply( Act::User->get_users( name => 'baz' ), [ $user ], "Found a pseudonymous user" );

