package Act::TimeSlot;
use Act::Event;
use Act::Talk;

sub get_items {
    my ( undef, %args ) = @_;

    # supprime les champs inutiles
    !/^(id|conf_id|datetime|room)$/ && delete $args{$_} for keys %args;
    my %args_talk  = ( %args, accepted => 1, lightning => 0 );
    my %args_event = %args;
    $args_talk{talk_id}   = delete $args_talk{id};
    $args_event{event_id} = delete $args_event{id};

    return [
        map {
            $_->{type} = ref;
            $_->{id}   = delete($_->{talk_id}) || delete($_->{event_id});
            bless $_, 'Act::TimeSlot';
        }
        @{ Act::Talk->get_talks( %args_talk ) },
        @{ Act::Event->get_events( %args_event ) }
    ];
}
*get_slots = \&get_items;

sub clone { bless {%{$_[0]}}, ref $_[0]; }

# a few accessors
for my $attr ( qw( id datetime room conf_id type title abstract duration ) ) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

1;

__END__

=head1 NAME

Act::TimeSlice - A class representing items to be shown on the schedule

=head1 DESCRIPTION

Act::TimeSlice objects represent both talks (Act::Talk) and non-talk events
(Act::Event) to be shown on the conference schedule.

Only Act::Talk and Act::Event objects are stored in the database. Act::TimeSlice
is an abstraction over both Act::Talk and Act::Event to simplify the schedule
related actions.

=cut

