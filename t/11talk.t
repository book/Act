use Test::More tests => 11;
use strict;
use t::Util;
use Act::Talk;
use Act::User;

# load some users
db_add_users();

my $user  = Act::User->new( login => 'book' );
my $user2 = Act::User->new( login => 'echo' );
my ( $talks, $talk, $talk1, $talk2, $talk3 );

# manually insert a talk
my $sth = $Request{dbh}->prepare_cached("INSERT INTO talks (user_id,duration,lightning,accepted,confirmed) VALUES(?,?,?,?,?);");
$sth->execute( $user->user_id, 12, 'f', 'f', 'f' );
$sth->finish();

$sth = $Request{dbh}->prepare_cached("SELECT * from talks WHERE user_id=?");
$sth->execute( $user->user_id);
my $hash = $sth->fetchrow_hashref;
$sth->finish;

$talk1 = Act::Talk->new( talk_id => $hash->{talk_id} );
isa_ok( $talk1, 'Act::Talk' );
is_deeply( $talk1, $hash, "Can insert a talk" );

TODO: {
   local $TODO = "1 talk and Act::Talk->new( dummy => 'dummy' ) don't DWIM";
   # when there's only one talk in the database,
   # this kind of call returns it
   $talk = Act::Talk->new( foo => 'bar' );
   is_deeply( $talk, undef, "no talk with foo => 'bar'" );
}

$talk = Act::Talk->new();
isa_ok( $talk, 'Act::Talk' );
is_deeply( $talk, {}, "create empty talk with new()" );

# create a talk
$talk2 = Act::Talk->create(
   title     => 'test',
   user_id   => $user2->user_id,
   duration  => 5,
   lightning => 'true',
   accepted  => '0',
   confirmed => 'false',
);
isa_ok( $talk2, 'Act::Talk' );

# talks are sorted by ids, which are incremental
$talks = $user->talks;
is_deeply( $talks, [ $talk1 ], "Got the user's talk" );

# add another talk
$talk3 = Act::Talk->create(
   title     => 'test 2',
   user_id   => $user->user_id,
   duration  => 40,
   lightning => 'FALSE',
   accepted  => 'F',
   confirmed => 'F',
);

# search method
$talks = Act::Talk->get_talks( duration => 40 );
is_deeply( $talks, [ $talk3 ], "40 minute talks" );
$talks = Act::Talk->get_talks( lightning => 'TRUE' );
is_deeply( $talks, [ $talk2 ], "lightning talks" );
$talks = Act::Talk->get_talks( user_id => $user->user_id );
is_deeply( $talks, [ $talk1, $talk3 ], "Got the user's talks" );

# this a Act::User method that encapsulate get_talks
$talks = $user->talks;
is_deeply( $talks, [ $talk1, $talk3 ], "Got the /'s talks" );

