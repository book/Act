package Act::TimeSlot;

use Act::Config;
use Act::Event;
use Act::Talk;
use Act::Track;
use Act::User;

use DateTime;
use DateTime::Format::Pg;
use List::Util qw(first);

sub get_items {
    my ( undef, %args ) = @_;

    # remove useless fields
    !/^(id|conf_id|datetime|room)$/ && delete $args{$_} for keys %args;
    my %args_talk  = ( %args, accepted => 1, lightning => 0 );
    my %args_event = %args;
    $args_talk{talk_id}   = delete $args_talk{id};
    $args_event{event_id} = delete $args_event{id};

    return [
        map {
            $_->{type} = ref;
            $_->{id}   = $_->{talk_id} || $_->{event_id};
            bless $_, 'Act::TimeSlot';
        }
        @{ Act::Event->get_events( %args_event ) },
        map { $_->{user}  = Act::User->new( user_id => $_->user_id );
              $_->{track} = Act::Track->new( track_id => $_->track_id )
                if $_->{track_id};
              $_ }
        grep !$_->{lightning},  # FIXME
        @{ Act::Talk->get_talks( %args_talk ) }
    ];
}
*get_slots = \&get_items;

sub clone { bless {%{$_[0]}}, ref $_[0]; }

# a few accessors
for my $attr ( qw( id datetime room conf_id type title abstract duration ) ) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

sub is_global { $_[0]{room} =~ /^(?:out|venue)$/; }

# get list of current and upcoming talks/events
sub get_current
{
    my $class = shift;
    my $now = shift;
    if ($now) {
        # convert from string to DateTime object
        $now = DateTime::Format::Pg->parse_timestamp_without_time_zone($now);
    }
    else {
        # current time in conference timezone
        $now = DateTime->now()->set_time_zone($Config->general_timezone);
    }
    # get scheduled talks and events, in chronological order
    my @ts = sort { DateTime->compare($a->datetime, $b->datetime) }
             grep { $_->datetime && $_->room }
             @{ $class->get_items( conf_id => $Request{conference} ) };

    # compute event end times, and index by room
    my %ts;
    for my $t (@ts) {
        $t->{end} = _end_date($t->datetime, $t->duration);
        push @{ $ts{$t->room} }, $t;
    }
    # current and upcoming talks
    my $limit = _end_date($now, 60);
    my %criteria = (
        current  => sub { $_[0]->datetime <= $now && $_[0]->{end} > $now },
        upcoming => sub { $_[0]->datetime > $now && $_[0]->datetime <= $limit },
    );
    my %interesting;
    for my $room (keys %ts) {
        for my $c (keys %criteria) {
            my $slot = first { $criteria{$c}->($_) } @{$ts{$room}};
            $interesting{$c}{$room} = $slot if $slot;
        }
    }
    return \%interesting;
}
sub _end_date
{
    my ($startdate, $duration) = @_;
    my $enddate = $startdate->clone;
    $enddate->add(minutes => $duration);
    return $enddate;
}

1;

__END__

=head1 NAME

Act::TimeSlot - A class representing items to be shown on the schedule

=head1 DESCRIPTION

Act::TimeSlot objects represent both talks (Act::Talk) and non-talk events
(Act::Event) to be shown on the conference schedule.

Only Act::Talk and Act::Event objects are stored in the database. Act::TimeSlot
is an abstraction over both Act::Talk and Act::Event to simplify the schedule
related actions.

=cut

