package Act::Handler::Talk::Import;
use strict;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::ICal;

use Act::Config;
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
        my (%talk, @talks);
        while (my $line = <$fh>) {
            $line =~ s/\n+$//;
            $line =~ s/\r+$//;
            if ($line eq 'BEGIN:VEVENT') {
                %talk = ();
            }
            elsif ($line =~ /^DTSTART.*:([\dT]+)$/) {
                $talk{dtstart} = $1;
            }
            elsif ($line =~ /^DTEND.*:([\dT]+)$/) {
                $talk{dtend} = $1;
            }
            elsif ($line =~ /^SUMMARY:(\d+)-/) {
                $talk{talk_id} = $1;
            }
            elsif ($line eq 'END:VEVENT') {
                # process talk
                my $t = Act::Talk->new(talk_id => $talk{talk_id});
                if ($t && !$t->lightning) {
                    my $dt2 = DateTime::Format::ICal->parse_datetime($talk{dtstart});
                    my $dt1;
                    $dt1 = DateTime::Format::Pg->parse_timestamp($t->datetime)
                        if $t->datetime;
                    # update talk with new datetime
                    if (!$dt1 || DateTime->compare($dt1, $dt2)) {
                        $dt1 = DateTime::Format::Pg->format_datetime($dt1) if $dt1;
                        $dt2 = DateTime::Format::Pg->format_datetime($dt2);
                        $t->update(datetime => $dt2);
                        push @talks, { 
                            %talk,
                            dt1   => $dt1,
                            dt2   => $dt2,
                            title => $t->title,
                        };
                    }
                }
            }
        }
        close $fh;
        $template->variables(talks => \@talks) if @talks;
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
