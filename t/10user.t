use Test::More tests => 50;
use strict;
use Act::User;
use t::Util;   # load the test database

my ($user, $user2);

# empty user
$user = Act::User->new;
isa_ok( $user, 'Act::User' );
is_deeply( $user, {}, "Empty new user" );

# manually insert a user and fetch it
my $sth = $Request{dbh}->prepare_cached("INSERT INTO users (login,passwd,email,country, first_name, last_name, timezone) VALUES(?,?,?,?,?,?,?);");
$sth->execute( 'test', 't3st', 'foo@bar.com', 'fr', 'first', 'last', 'Europe/Paris' );
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
    pm_group  => 'paris.pm',
    timezone => 'Europe/Paris',
);
isa_ok( $user, 'Act::User' );
is( $user->login, 'test2', "check accessor" );

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

# update a user
$user = Act::User->new( login => 'test' );
$user->update(email => 'bar@baz.com', login => 'frobb', nick_name => 'baz' );
$user = Act::User->new( login => 'frobb' );
isa_ok( $user, 'Act::User' );
is($user->login, 'frobb', 'Updated login');
is($user->email, 'bar@baz.com', 'Updated email');

# test clone
$user  = Act::User->new( login => 'frobb' );
$user2 = $user->clone;
is_deeply( $user2, $user, "clone copies everything" );

for( keys %$user2 ) {
    $user2->{$_} = reverse $user2->$_;
    is( $user2->$_, reverse( $user->$_ ),
        "clone has a distinct $_");
}

# the bio table
$sth = $Request{dbh}->prepare_cached(
    "INSERT INTO bios ( user_id, lang, bio ) VALUES (?, ?, ?)"
);

$sth->execute( $user->user_id, 'fr', 'French bio' );
$sth->execute( $user->user_id, 'en', 'English bio' );
$Request{dbh}->commit;

is_deeply( $user->bio, { fr => 'French bio', en => 'English bio' }, "Bio" );

# find a twin in the db
my $twins = $user->possible_duplicates();
is( grep( { $_->user_id == $user->user_id } @$twins ),
    0, "User is not his own twin" );
is( scalar @$twins, 1, "Found 1 possible duplicate" );
is( $user->nick_name, $twins->[0]->nick_name, "  based on the nick_name" );

# full_name
$user = Act::User->new( full_name => 'Foo bar' );
isa_ok( $user, 'Act::User' );
is( $user->first_name, 'Foo',     'first name Foo' );
is( $user->last_name,  'bar',     'last name bar' );
is( $user->full_name,  'Foo bar', 'full name Foo bar' );
