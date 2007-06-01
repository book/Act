package Act::Handler::Talk::ExportCSV;
use strict;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;
use Text::xSV;

use Act::Config;
use Act::Talk;

my @ROWS = qw(
 talk_id
 user_id
 title
 abstract
 url_abstract
 url_talk
 duration
 lightning
 accepted
 confirmed
 comment
 room
 datetime
 track_id
 level
);

sub handler
{
    # only for orgas
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # get talks
    my $talks = Act::Talk->get_talks(conf_id => $Request{conference});

    # generate CSV report
    my $csv = Text::xSV->new( header => \@ROWS );
    $Request{r}->send_http_header('text/csv; charset=UTF-8');
    $Request{r}->print($csv->format_header());

    for my $talk (@$talks) {
        # convert datetime
        $talk->{datetime} = DateTime::Format::Pg->format_datetime($talk->datetime)
            if ($talk->datetime);
        # print in CSV format
        $Request{r}->print($csv->format_row( map $talk->$_, @ROWS ));
    }
}

1;
__END__

=head1 NAME

Act::Handler::Talk::ExportCSV - export talks to CSV format

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
