use Test::More tests => 7;
use Act::User;
use t::Util;   # load the test database

my ($user, $user2);

# empty user
$user = Act::User->new;
isa_ok( $user, 'Act::User' );
is_deeply( $user, {}, "Empty new user" );

# manually insert a user and fetch it
my $sth = $Request{dbh}->prepare_cached("INSERT INTO users (login,passwd,email,country) VALUES(?,?,?,?);");
$sth->execute( 'test', 't3st', 'foo@bar.com', 'fr' );
$sth->finish();

$user = Act::User->new( login => 'test' );
isa_ok( $user, 'Act::User' );

# create a new user
$user = Act::User->create(
    login   => 'test2',
    passwd  => 't3st',
    email   => 'bar@bar.com',
    country => 'en',
);
isa_ok( $user, 'Act::User' );

# ENOSUCHUSER
$user = Act::User->new( login => 'foo' );
is( $user, undef, "User foo not found" );

# fetch a user
$user = Act::User->new( login => 'test' );
isa_ok( $user, 'Act::User' );

$user2 = Act::User->new( user_id => $user->user_id );
is_deeply( $user, $user2, "Same data from login or user_id" );

