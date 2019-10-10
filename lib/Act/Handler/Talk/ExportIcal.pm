package Act::Handler::Talk::ExportIcal;
use strict;
use parent 'Act::Handler';

use Act::Abstract;
use Act::Config;
use Act::Event;
use Act::Talk;
use Act::TimeSlot;
use Act::Util;
use Data::ICal::Entry::Event;
use Data::ICal::TimeZone;
use Data::ICal;

#
# handler()
# -------
sub handler {
    # access control
    unless ( $Request{user} && $Request{user}->is_talks_admin
        || $Config->talks_show_schedule )
    {
        $Request{status} = 404;
        return;
    }

    my $timeslots = _get_timeslots();
    export($timeslots);
    return;
}


#
# export()
# ------
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


#
# _output()
# -------
sub _output {
    my $cal = shift;

    my $out = $cal->as_string;

    $Request{r}->send_http_header('text/calendar; charset=UTF-8');
    $Request{r}->print($out);
}


#
# _get_timeslots()
# --------------
sub _get_timeslots {
    my @events = @{ Act::Event->get_events( conf_id => $Request{conference} ) };
    my @talks  = grep !$_->{lightning},
        @{ Act::Talk->get_talks( conf_id => $Request{conference} ) };

    # get all talks/events
    my $timeslots = [
        map {
            $_->{type} = ref;
            $_->{id} = $_->{talk_id} || $_->{event_id};

            if ($_->{type} eq "Act::Talk") {
                $_->{user}  = Act::User->new( user_id => $_->user_id );
                $_->{track} = Act::Track->new( track_id => $_->track_id )
                    if $_->{track_id};
                $_->{stars} = $_->stars;
            }

            bless $_, 'Act::TimeSlot';
        } @events, @talks
    ];

    return $timeslots;
}


#
# _get_cal_entry_defaults()
# -----------------------
sub _get_cal_entry_defaults {
    my %defaults = (
        datetime =>
            format_datetime_string( $Config->talks_start_date ),
        duration =>
            ( sort { $a <=> $b } keys %{ $Config->talks_durations } )[0],
    );

    return \%defaults;
}


#
# _setup_calendar_obj()
# -------------------
sub _setup_calendar_obj {
    my $cal = Data::ICal->new();
    my $tz_name = $Config->general_timezone;

    $cal->add_properties(
        prodid         => "-//Act//Data::ICal $Data::ICal::VERSION//EN",
        calscale       => "GREGORIAN",
        "X-WR-CALNAME" => $Config->name->{ $Request{language} },
        "X-WR-TIMEZONE"=> $tz_name,
    );

    my $tzdef = Data::ICal::TimeZone->new(timezone => $tz_name);
    $cal->add_entry($tzdef->definition);

    return $cal;
}


#
# _viewable()
# ---------
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


#
# _build_event()
# ------------
sub _build_event {
    my $ts             = shift;
    my $entry_defaults = shift;

    # set defaults
    $ts->{$_} ||= $entry_defaults->{$_} for keys %$entry_defaults;

    # compute start and end time
    my $tz_name = $Config->general_timezone;
    my $dtstart = $ts->datetime->set_time_zone($tz_name);
    my $dtend   = $dtstart->clone;
    $dtend->add( minutes => $ts->duration );

    # uid is used to identify this event
    # (see Act::Handler::Talk::Import)
    ( my $type = $ts->type ) =~ s/^Act:://;
    my $url = $Config->general_full_uri . join( '/', lc($type), $ts->{id} );
    my $event = Data::ICal::Entry::Event->new();

    $event->add_properties(
        dtstart     => [
            $dtstart->ymd("") . "T" . $dtstart->hms(""), { tzid => $tz_name },
        ],
        dtend       => [
            $dtend->ymd("") . "T" . $dtend->hms(""), { tzid => $tz_name },
        ],
        summary     => $ts->title,
        uid         => $url,
        url         => $url,
        description => join '',
            map {
                  $_->{text} ? $_->{text}
                : $_->{talk} ? $_->{talk}->title
                : $_->{user} ? $_->{user}->public_name
                : undef
            } @{ Act::Abstract::chunked( $ts->abstract ) }
    );

    $event->add_properties( location => $Config->rooms->{ $ts->room } )
        if $ts->room;

    # for a talk, add a few more properties
    if ($ts->{type} eq "Act::Talk") {
        # add the speaker's name
        $event->add_properties(organizer => $ts->{user}->public_name);

        # add the list of known attendees
        my @attendees = @{ Act::User->attendees($ts->{id}) };
        $event->add_properties(comment => @attendees." attendees");

        for my $user (@attendees) {
            $event->add_properties(attendee => $user->public_name);
        }
    }

    return $event;
}


1;
__END__

=head1 NAME

Act::Handler::Talk::ExportIcal - export talk/event schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
