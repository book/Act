use Test::More tests => 7;
use Act::Event;
use strict;
use Test::Lib;
use Test::Act::Util;

# manually insert an event
my $sth = $Request{dbh}->prepare_cached("INSERT INTO events (conf_id,duration,title,abstract) VALUES(?,?,?,?)");
$sth->execute( 'conf', 90, 'lunch', 'lunch time' );
$sth->finish();

# there is only one row
$sth = $Request{dbh}->prepare_cached("SELECT * from events LIMIT 1");
$sth->execute();
my $hash = $sth->fetchrow_hashref;
$sth->finish;

my $event = Act::Event->new( event_id => $hash->{event_id} );
isa_ok( $event, 'Act::Event' );
is_deeply( $event, $hash, "Can insert a event" );

$event = Act::Event->new();
isa_ok( $event, 'Act::Event' );
is_deeply( $event, {}, "create empty event with new()" );

# create a event
$event = Act::Event->create(
   title     => 'test',
   conf_id   => 'conf',
   duration  => 5,
);
isa_ok( $event, 'Act::Event' );

# fetch an event
my $id = $event->event_id;
my $event2 = Act::Event->new( event_id => $id );
$event2->update( title => 'new test' );

$event = Act::Event->new( event_id => $id );
is_deeply( $event, $event2, "field modified by update" );

# try deleting the event
$event->delete;

is( Act::Event->new( event_id => $id ), undef, "Event removed" );

