use Test::More tests => 8;
use Act::Event;
use Act::Talk;
use Act::TimeSlot;
use t::Util;

db_add_users;
db_add_talks;
db_add_events;

# 1 non-lightning talk accepted (out of 3), 1 event
my $slots = Act::TimeSlot->get_items( conf_id => 'conf' );
is( @$slots, 2, "Got all timeslots" );
isa_ok( $_, 'Act::TimeSlot' ) for @$slots;

my ($event) = grep { $_->{type} eq 'Act::Event' } @$slots;
is_deeply( $event, {
    duration  => '90',
    room      => 'out',
    datetime  => undef,
    conf_id   => 'conf',
    url_abstract => undef,
    id        => $event->{id},
    title     => 'Lunch',
    abstract  => 'Lunch, outside of the conference premises',
    type      => 'Act::Event',
}, "Got the correct event" );

# check the accessors
is( $event->title, 'Lunch', "title accessor ok" );
is( $event->type,  'Act::Event', "type accessor ok" );
ok( $event->is_global, "event is global" );

my ($event_orig) = Act::Event->new( event_id => $event->{id} );

# modifies the timeslot back into an event
$event->{event_id} = delete $event->{id};
delete $event->{type};
is_deeply( $event_orig, $event, "Same event" );

