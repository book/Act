package Act::Handler::Talk::Import;
use strict;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::ICal;

use Act::Config;
use Act::Event;
use Act::Talk;
use Act::Template::HTML;

sub handler
{
    # only for admins
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new;
    if (   $Request{args}{update}
        && $Request{r}->upload()
        && defined(my $fh = $Request{r}->upload()->fh()))
    {
        # process uploaded ics data
        my (%timeslot, @timeslots);
        while (my $line = <$fh>) {
            $line =~ s/\n+$//;
            $line =~ s/\r+$//;
            if ($line eq 'BEGIN:VEVENT') {
                %timeslot = ();
            }
            elsif ($line =~ /^DTSTART.*:([\dT]+)$/) {
                $timeslot{dtstart} = $1;
            }
            elsif ($line =~ /^DTEND.*:([\dT]+)$/) {
                $timeslot{dtend} = $1;
            }
            elsif ($line =~ /^SUMMARY:(\w+)-(\d+)-/) {
                if ($1 eq 'talk') {
                    $timeslot{id_name} = 'talk_id';
                    $timeslot{id} = $2;
                    $timeslot{type} = 'Act::Talk';
                }
                elsif ($1 eq 'event') {
                    $timeslot{id_name} = 'event_id';
                    $timeslot{id} = $2;
                    $timeslot{type} = 'Act::Event';
                }
            }
            elsif ($line eq 'END:VEVENT' && $timeslot{type}) {
                # process event
                my $e = $timeslot{type}->new($timeslot{id_name} => $timeslot{id}, conf_id => $Request{conference});
                if ($e && ($timeslot{type} ne 'talk' || !$e->lightning)) {
                    my $dt1 = $e->datetime;
                    my $dt2 = DateTime::Format::ICal->parse_datetime($timeslot{dtstart});
                    # update talk with new datetime
                    if (!$dt1 || DateTime->compare($dt1, $dt2)) {
                        $dt1 = DateTime::Format::Pg->format_datetime($dt1) if $dt1;
                        $dt2 = DateTime::Format::Pg->format_datetime($dt2);
                        $e->update(datetime => $dt2);
                        push @timeslots, { 
                            %$e,
                            %timeslot,
                            dt1   => $dt1,
                            dt2   => $dt2,
                        };
                    }
                }
            }
        }
        close $fh;
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
