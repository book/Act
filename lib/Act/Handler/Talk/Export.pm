package Act::Handler::Talk::Export;
use strict;

use Apache::Constants qw(FORBIDDEN);
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::ICal;

use Act::Config;
use Act::Event;
use Act::Talk;
use Act::Template;
use Act::TimeSlot;

use constant CID => '532E0386-A523-11D8-A904-000393DB4634';
use constant UID => "5F451677-A523-11D8-928A-000393DB4634";

sub handler
{
    # access control
    unless ($Request{user} && $Request{user}->is_orga || $Config->talks_show_schedule) {
        $Request{status} = FORBIDDEN;
        return;
    }
    # get all talks/events
    my $timeslots = [
        map {
            $_->{type} = ref;
            $_->{id}   = $_->{talk_id} || $_->{event_id};
            bless $_, 'Act::TimeSlot';
        }
        @{ Act::Event->get_events(conf_id => $Request{conference}) },
        grep !$_->{lightning},
        @{ Act::Talk->get_talks(conf_id => $Request{conference}) }
    ];
    # generate iCal events
    my %defaults = (
        datetime => DateTime::Format::Pg->parse_timestamp($Config->talks_start_date),
        duration => (sort { $a <=> $b } keys %{$Config->talks_durations})[0],
    );
    my @events;
    for my $ts (@$timeslots) {
        next unless ($Request{user} && $Request{user}->is_orga)
                 || (   ($ts->type ne 'Act::Talk' || $ts->{accepted})
                     && $ts->datetime && $ts->duration && $ts->room
                    );
        # set defaults
        $ts->{$_} ||= $defaults{$_} for keys %defaults;
        # compute end time
        my $dtstart = $ts->datetime;
        my $dtend = $dtstart->clone;
        $dtend->add(minutes => $ts->duration);
        # title is used to identify this event
        # (see Act::Handler::Talk::Import)
        (my $type = $ts->type) =~ s/^Act:://;
        push @events, {
            dtstart => DateTime::Format::ICal->format_datetime($dtstart),
            dtend   => DateTime::Format::ICal->format_datetime($dtend),
            title   => join('-', lc($type), $ts->id, $ts->title),
            uid     => sprintf('%04x', $ts->id) . substr(UID,4),
        };
    }
    # current timestamp
    my $now = DateTime->now;
    $now->set_time_zone('UTC');

    # process the template
    my $template = Act::Template->new(PRE_CHOMP => 1);
    $template->variables(
        events   => \@events,
        now      => DateTime::Format::ICal->format_datetime($now),
        cid      => CID,
        calname  => $Config->name->{$Request{language}},
    );
    $Request{r}->send_http_header('text/calendar; charset=UTF-8');
    $template->process('talk/ical');
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Export - export talk/event schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
