package Act::Handler::User::UpdateMyTalks;
use strict;

use Act::Talk;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    if ($Request{user}->has_registered) {
        $Request{user}->update_my_talks(
            map Act::Talk->new(talk_id => $_, conf_id => $Request{conference}),
            map /^mt-(\d+)$/, keys %{$Request{args}}
        );
    }
    return Act::Util::redirect(make_uri('schedule'))
}

1;

=head1 NAME

Act::Handler::User::UpdateMyTalks - update a user's my_talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
