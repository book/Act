package Act::Handler::User::UpdateMyTalks;
use strict;

use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    if ($Request{user}->has_registered) {
        $Request{user}->update_my_talks(
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
