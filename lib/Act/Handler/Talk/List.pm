package Act::Handler::Talk::List;
use strict;
use parent 'Act::Handler';
use Act::Config;
use Act::Template::HTML;
use Act::Tag;
use Act::Talk;
use Act::Track;
use Act::Util;
use Act::Handler::Talk::Util;

sub handler
{
    # searching by tag
    my ($tag, $talks);
    if ($Request{path_info}) {
        my ($type, $stag) = split '/', $Request{path_info};
        if ($type eq 'tag' && $stag) {
            $tag = Act::Util::normalize($stag);
            my @talk_ids = Act::Tag->find_tagged(
                conf_id     => $Request{conference},
                type        => 'talk',
                tags        => [ $tag ],
            );
            $talks = [ map Act::Talk->new(talk_id => $_), @talk_ids ];
        }
        else {
            # invalid path_info, redirect to canonical uri
            Act::Util::redirect(Act::Util::make_uri('talks'));
            return;
        }
    }
    # retrieve talks and speaker info
    $talks ||= Act::Talk->get_talks( conf_id => $Request{conference} );
    my $talks_total = scalar @$talks;
    $_->{user} = Act::User->new( user_id => $_->user_id ) for @$talks;

    # sort talks
    $talks = [
        sort {
                   $a->lightning <=> $b->lightning
                || lc $a->{user}->last_name cmp lc $b->{user}->last_name
                || lc $a->{user}->first_name cmp lc $b->{user}->first_name
                || $a->talk_id <=> $b->talk_id
        }
        grep {    $Config->talks_show_all
               || $_->accepted
               || ($Request{user} && (   $Request{user}->is_talks_admin
                                      || $Request{user}->user_id == $_->user_id))
        } @$talks
    ];

    # accept / unaccept talks
    if ($Request{user} && $Request{user}->is_talks_admin && $Request{args}{ok}) {
        for my $t (@$talks) {
            if ($t->accepted && !$Request{args}{$t->talk_id}) {
                $t->update(accepted => 0 );
                $t->{accepted} = undef;
            }
            elsif (!$t->accepted && $Request{args}{$t->talk_id}) {
                $t->update(accepted => 1 );
                Act::Handler::Talk::Util::notify_accept($t);
            }
        }
    }

    # compute some global information
    my ($accepted, $lightnings, $duration ) = ( 0, 0, 0 );
    $_->accepted && do { $accepted++; $_->lightning ? $lightnings++ : ( $duration += $_->duration) } for @$talks;

    # link the talks to their tracks (keeping the talks ordered)
    my $tracks = Act::Track->get_tracks( conf_id => $Request{conference} );

    # add the "empty track" for talks without a track
    if( @$tracks ) {
        unshift @$tracks, my $t = Act::Track->new();
        @{$t}{qw( conf_id track_id title description )}
            = ( $Request{conference}, '', '', '' );
    }
    for my $track ( @$tracks ) {
        my $id = $track->track_id;
        $track->{talks} = [ grep { $_->track_id == $id } @$talks ];
    }

    # get tag cloud
    my $tagcloud = Act::Tag->get_cloud(
                    conf_id => $Request{conference},
                    type   => 'talk',
                    filter => [ map $_->talk_id, @$talks ],
    );

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables_raw(tagcloud => $tagcloud);
    $template->variables(
        talks          => $talks,
        talks_total    => $talks_total,
        talks_accepted => $accepted,
        talks_duration => $duration,
        talks_lightning => $lightnings,
        tracks         => $tracks,
        tag            => $tag,
    ); 
    $template->process('talk/list');
    return;
}

1;
__END__

=head1 NAME

Act::Handler::User::List - show all talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
