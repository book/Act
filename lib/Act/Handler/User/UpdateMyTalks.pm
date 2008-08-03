package Act::Handler::User::UpdateMyTalks;
use strict;

use Act::Talk;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    my $day = $Request{args}{day};
    if ($Request{user}->has_registered && $day) {
        $Request{user}->update_my_talks(
            (map Act::Talk->new(talk_id => $_, conf_id => $Request{conference}),
             map /^mt-(\d+)$/, keys %{$Request{args}}),
            grep { $_->datetime && $_->datetime->ymd ne $day }
             @{ $Request{user}->my_talks }
        );
    }
    return Act::Util::redirect(make_uri('schedule', day => $day))
}

1;

=head1 NAME

Act::Handler::User::UpdateMyTalks - update a user's my_talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
