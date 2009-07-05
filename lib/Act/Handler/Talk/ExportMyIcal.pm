package Act::Handler::Talk::ExportMyIcal;
use strict;

use Apache::Constants qw(FORBIDDEN);

use Act::Config;
use Act::Event;
use Act::TimeSlot;
use Act::Util;
use Act::Handler::Talk::ExportIcal;

sub handler
{
    # registered users only
    return Act::Util::redirect(make_uri('register'))
      unless $Request{user}->has_registered;

    my @timeslots =
             map Act::TimeSlot::upgrade($_),
             @{ Act::Event->get_events( conf_id => $Request{conference} ) },
             @{ $Request{user}->my_talks };

    Act::Handler::Talk::ExportIcal::export(\@timeslots);
}

1;
__END__

=head1 NAME

Act::Handler::Talk::ExportMyIcal - export personal schedule to iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
