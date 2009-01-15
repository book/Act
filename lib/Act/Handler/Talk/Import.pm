package Act::Handler::Talk::Import;
use strict;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use Data::ICal;
use Data::ICal::DateTime;
use DateTime::Format::Pg;

use Act::Config;
use Act::Event;
use Act::Talk;
use Act::Template::HTML;

sub handler
{
    # only for admins
    unless ($Request{user}->is_talks_admin) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new;
    if (   $Request{args}{update}
        && $Request{r}->upload()
        && defined(my $fh = $Request{r}->upload()->fh()))
    {
        local $/ = undef;
        my $data = <$fh>;
        close $fh;
    
        # process uploaded ics data
        my $cal = Data::ICal->new(data => $data);
        my (%timeslot, @timeslots);
        for my $event ($cal->events) {
            my $uid = $event->property('uid')->[0]->value;
            next unless $uid;
            my ($type, $id) = (split '/', $uid)[-2, -1];
            next unless $id && ($type eq 'talk' || $type eq 'event');

            $timeslot{id_name} = $type ."_id";
            $timeslot{id} = $id;
            $timeslot{type} = 'Act::' . ucfirst $type;

            # process event
            my $e = $timeslot{type}->new($type ."_id" => $id, conf_id => $Request{conference});
            if ($e && ($timeslot{type} ne 'talk' || !$e->lightning)) {
                my $dt1 = $e->datetime;
                my $dt2 = $event->start;
                # update talk with new datetime
                if ($dt2 && (!$dt1 || DateTime->compare($dt1, $dt2))) {
                    $e->update(datetime => DateTime::Format::Pg->format_datetime($dt2));
                    push @timeslots, { 
                        %$e,
                        %timeslot,
                        dt1   => $dt1,
                        dt2   => $dt2,
                    };
                }
            }
        }
        $template->variables(timeslots => \@timeslots) if @timeslots;
    }
    # display results
    $template->process('talk/import');
}
1;
__END__

=head1 NAME

Act::Handler::Talk::Import - import talk start times from iCalendar format (RFC2445) .ics files.

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
