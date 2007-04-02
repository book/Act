package Act::Handler::Talk::Export;
use strict;

use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::ICal;
use Encode qw(from_to);

use Act::Config;
use Act::Talk;
use Act::Template;
use Act::Handler::Talk::Schedule;

use constant CID => '532E0386-A523-11D8-A904-000393DB4634';
use constant UID => "5F451677-A523-11D8-928A-000393DB4634";

sub handler
{
    # get the table information
    my ($talks) = Act::Handler::Talk::Schedule::compute_schedule();
    # keep only the Act::TimeSlot objects
    $talks = [ map { grep { ref eq 'Act::TimeSlot' } @$_ }
               map { @$_ } values %$talks ];

    # current timestamp
    my $now = DateTime->now;
    $now->set_time_zone($Config->general_timezone);

    # generate iCal events for each talk
    my @talks;
    for my $t (@$talks) {
        my $dtstart = $t->datetime;
        my $dtend = $dtstart->clone;
        $dtend->add(minutes => $t->duration);
        push @talks, {
            dtstart => DateTime::Format::ICal->format_datetime($dtstart),
            dtend   => DateTime::Format::ICal->format_datetime($dtend),
            title   => join('-', $t->id, from_to($t->title, 'ISO-8859-1', 'UTF-8')),
            uid     => sprintf('%04x', $t->id) . substr(UID,4),
        };
    }

    # process the template
    my $template = Act::Template->new(PRE_CHOMP => 1);
    $template->variables(
        talks    => \@talks,
        now      => DateTime::Format::ICal->format_datetime($now),
        timezone => $Config->general_timezone,
        cid      => CID,
        calname  => $Config->name->{$Request{language}},
    );
    $Request{r}->send_http_header('text/calendar');
    $template->process('talk/ical');
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Export - export talk schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
