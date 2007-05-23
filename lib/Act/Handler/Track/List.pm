package Act::Handler::Track::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::Track;

sub handler
{
    # only for orgas
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # retrieve tracks
    my $tracks = Act::Track->get_items(conf_id => $Request{conference});
    
    # retrieve number of talks per track
    for my $t (@$tracks) {
        my $talks = Act::Talk->get_talks(
            conf_id  => $Request{conference},
            track_id => $t->track_id,
        );
        $t->{talks} = {
            total     => scalar(@$talks),
            accepted  => scalar(grep { $_->accepted } @$talks),
            confirmed => scalar(grep { $_->confirmed } @$talks),
        };
    }
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(tracks => $tracks);
    $template->process('track/list');
}

1;
__END__

=head1 NAME

Act::Handler::Track::List - show all tracks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
