package Act::Handler::Talk::Export;
use strict;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::ICal;
use Text::Iconv;

use Act::Config;
use Act::Talk;
use Act::Template;

use constant CID => 'AEDDA55C-ACDC-11D7-9018-000393DB4634';
use constant UID => "CBBCAB60-ACDC-11D7-9018-000393DB4634";

sub handler
{
    # only for admins
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # latin1 to utf8 converter
    my $to_utf8 = Text::Iconv->new('ISO-8859-1', 'UTF-8');

    # retrieve talks
    my $talks = Act::Talk->get_talks(
        conf_id  => $Request{conference},
        accepted => 1,
    );

    # current timestamp
    my $now = DateTime->now;
    $now->set_time_zone($Config->general_timezone);

    # default timestamp for talks
    my $dstart = DateTime::Format::Pg->parse_timestamp($Config->talks_start_date);

    # generate iCal events for each talk
    my @talks;
    my $uid = UID;
    for my $t (@$talks) {
        unless ($t->lightning) {
            my $dtstart = $t->datetime
                        ? DateTime::Format::Pg->parse_timestamp($t->datetime)
                        : $dstart;
            my $dtend = $dtstart->clone;
            $dtend->add(minutes => $t->duration);
            push @talks, {
                dtstart => DateTime::Format::ICal->format_datetime($dtstart),
                dtend   => DateTime::Format::ICal->format_datetime($dtend),
                title   => $to_utf8->convert($t->title),
                uid     => $uid++,
            };
        }
    }

    # process the template
    my $template = Act::Template->new(PRE_CHOMP => 1);
    $template->variables(
        talks    => \@talks,
        now      => DateTime::Format::ICal->format_datetime($now),
        timezone => $Config->general_timezone,
        cid      => CID,
        calname  => $Request{conference},
    );
    $Request{r}->send_http_header('text/plain');
    $template->process('talk/ical');
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Export - export talk schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
