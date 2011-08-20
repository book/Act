package Act::Handler::User::UpdateMyTalks;
use strict;
use parent 'Act::Handler';

use Act::Talk;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    if ($Request{user}->has_registered) {
        if (my $day = $Request{args}{day}) {                # update one day (from schedule page)
            $Request{user}->update_my_talks(
                (map Act::Talk->new(talk_id => $_, conf_id => $Request{conference}),
                 map /^mt-(\d+)$/, keys %{$Request{args}}),
                grep { $_->datetime && $_->datetime->ymd ne $day }
                 @{ $Request{user}->my_talks }
            );
            return Act::Util::redirect(make_uri('schedule', day => $day));
        }
        elsif (my $talk_id = $Request{args}{talk_id}) {     # update one talk (from talk page)
            my $talk = Act::Talk->new(talk_id => $talk_id, conf_id => $Request{conference});
            my @my_talks = grep { $_->talk_id != $talk_id } @{ $Request{user}->my_talks };
            $Request{user}->update_my_talks(
                $Request{args}{"mt-$talk_id"}       # is talk currently selected?
              ? ( @my_talks, $talk )               # add
              : ( @my_talks )                      # remove
            );
            return Act::Util::redirect(make_uri_info('talk', $talk_id));
        }
    }
    return Act::Util::redirect(make_uri('schedule'));
}

sub ajax_handler
{
    if ($Request{user}->has_registered && $Request{args}{talk_id}) {
        my $talk = Act::Talk->new(talk_id => $Request{args}{talk_id}, conf_id => $Request{conference});
        my $my_talks = $Request{user}->my_talks;
        $Request{user}->update_my_talks(
            grep( { $_->talk_id == $talk->talk_id } @$my_talks)         # is talk currently selected?
              ? ( grep { $_->talk_id != $talk->talk_id } @$my_talks )   # yes, remove
              : ( @$my_talks, $talk )                                   # no, add it
        );
    }

    $Request{status} = 204;
    return;
}

1;

=head1 NAME

Act::Handler::User::UpdateMyTalks - update a user's my_talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
