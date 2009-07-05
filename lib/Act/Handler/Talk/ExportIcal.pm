package Act::Handler::Talk::ExportIcal;
use strict;

use Apache::Constants qw(FORBIDDEN);
use DateTime::Format::Pg;
use Data::ICal;
use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

use Act::Abstract;
use Act::Config;
use Act::Event;
use Act::Talk;
use Act::TimeSlot;
use Act::Util;

sub handler {

    # access control
    unless ( $Request{user} && $Request{user}->is_talks_admin
        || $Config->talks_show_schedule )
    {
        $Request{status} = FORBIDDEN;
        return;
    }
    my $timeslots = _get_timeslots();
    export($timeslots);
}

sub export {
    my $timeslots = shift;

    # generate iCal events
    my $entry_defaults = _get_cal_entry_defaults();

    my $cal = _setup_calendar_obj();
    for my $ts (@$timeslots) {
        next unless _viewable($ts);
        my $event = _build_event( $ts => $entry_defaults );
        $cal->add_entry($event);
    }
    _output($cal);
}

sub _output {
    my $cal = shift;
    $Request{r}->send_http_header('text/calendar; charset=UTF-8');
    $Request{r}->print( $cal->as_string() );
}

sub _get_timeslots {

    # get all talks/events
    my $timeslots = [
        map {
            $_->{type} = ref;
            $_->{id} = $_->{talk_id} || $_->{event_id};
            bless $_, 'Act::TimeSlot';
            } @{ Act::Event->get_events( conf_id => $Request{conference} ) },
        grep !$_->{lightning},
        @{ Act::Talk->get_talks( conf_id => $Request{conference} ) }
    ];

    return $timeslots;
}

sub _get_cal_entry_defaults {
    my %defaults = (
        datetime =>
            DateTime::Format::Pg->parse_timestamp( $Config->talks_start_date ),
        duration =>
            ( sort { $a <=> $b } keys %{ $Config->talks_durations } )[0],
    );
    return \%defaults;
}

sub _setup_calendar_obj {

    my $cal = Data::ICal->new();
    $cal->add_properties(
        calscale       => 'GREGORIAN',
        'X-WR-CALNAME' => $Config->name->{ $Request{language} },
    );

    return $cal;
}

sub _viewable {
    my $ts = shift;
    return 0
        unless ( $Request{user} && $Request{user}->is_talks_admin )
        || ( ( $ts->type ne 'Act::Talk' || $ts->{accepted} )
        && $ts->datetime
        && $ts->duration
        && $ts->room );
    return 1;

}

sub _build_event {
    my $ts             = shift;
    my $entry_defaults = shift;

    # set defaults
    $ts->{$_} ||= $entry_defaults->{$_} for keys %$entry_defaults;

    # compute end time
    my $dtstart = $ts->datetime;
    my $dtend   = $dtstart->clone;
    $dtend->add( minutes => $ts->duration );

    # uid is used to identify this event
    # (see Act::Handler::Talk::Import)
    ( my $type = $ts->type ) =~ s/^Act:://;
    my $url = $Config->general_full_uri . join( '/', lc($type), $ts->{id} );
    my $event = Data::ICal::Entry::Event->new();
    $event->start($dtstart);
    $event->end($dtend);
    $event->add_properties(
        summary     => $ts->title,
        uid         => $url,
        url         => $url,
        description => join '',
        map {
                  $_->{text} ? $_->{text}
                : $_->{talk} ? $_->{talk}->title
                : $_->{user} ? $_->{user}->pseudonymous && $_->{user}->nick_name
                || join( ' ', $_->{user}->first_name, $_->{user}->last_name )
                : undef
            } @{ Act::Abstract::chunked( $ts->abstract ) }
    );
    $event->add_properties( location => $Config->rooms->{ $ts->room }, )
        if $ts->room;
    return $event;
}

1;
__END__

=head1 NAME

Act::Handler::Talk::ExportIcal - export talk/event schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
