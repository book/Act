package Act::Handler::Talk::Favorites;
use strict;

use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::User;

sub handler
{
    # retrieve tracks
    my %tracks = map { $_->track_id => $_ }
            @{ Act::Track->get_tracks(conf_id => $Request{conference}) };

    # retrieve user_talks, most popular first
    my $sth = $Request{dbh}->prepare_cached(
        'SELECT talk_id, COUNT(talk_id) FROM user_talks WHERE conf_id = ? GROUP BY talk_id ORDER BY count DESC');
    $sth->execute( $Request{conference} );
    my @favs;
    while (my ($talk_id, $count) = $sth->fetchrow_array()) {
        my $talk = Act::Talk->new(talk_id => $talk_id);
        if ($Config->talks_show_all
         || $talk->accepted
         || ($Request{user} && (   $Request{user}->is_talks_admin
                                || $Request{user}->user_id == $talk->user_id)))
        {
            push @favs, { talk  => $talk,
                          count => $count,
                          user  => Act::User->new(user_id => $talk->user_id),
                        };
        }
    }
    # link the talks to their tracks (keeping the talks ordered)
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        favs   => \@favs,
        tracks => \%tracks,
    );
    $template->process('talk/favorites');
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Favorites - show users' favorites talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
