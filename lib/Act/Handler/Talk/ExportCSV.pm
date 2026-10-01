package Act::Handler::Talk::ExportCSV;
use strict;
use parent 'Act::Handler';

use DateTime;
use Text::xSV;

use Act::Config;
use Act::Talk;
use Act::User;
use Act::Util qw(format_datetime_string);

my @UROWS = qw(
 user_id
 first_name
 last_name
 nick_name
);
my @TROWS = qw(
 talk_id
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
 lang
);

sub handler
{
    # only for orgas
    unless ($Request{user}->is_talks_admin) {
        $Request{status} = 404;
        return;
    }
    # get talks
    my $talks = Act::Talk->get_talks(conf_id => $Request{conference});

    # generate CSV report
    my $csv = Text::xSV->new( header => [ @UROWS, @TROWS ] );
    $Request{r}->send_http_header('text/csv; charset=UTF-8');
    $Request{r}->print($csv->format_header());

    for my $talk (@$talks) {
        # convert datetime
        $talk->{datetime} = format_datetime_string($talk->datetime)
            if ($talk->datetime);
        # fetch user
        my $user = Act::User->new(user_id => $talk->user_id);

        # print in CSV format
        $Request{r}->print($csv->format_row(
            map($user->$_, @UROWS),
            map($talk->$_, @TROWS),
        ));
    }
    return;
}

1;
__END__

=head1 NAME

Act::Handler::Talk::ExportCSV - export talks to CSV format

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
