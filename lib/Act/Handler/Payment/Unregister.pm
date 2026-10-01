package Act::Handler::Payment::Unregister;

use strict;
use parent 'Act::Handler';

use Act::Template::HTML;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    # for treasurers only
    unless ($Request{user} && $Request{user}->is_treasurer)
    {
        $Request{status} = 404;
        return;
    }
    unless ($Request{args}{user_id} =~ /^\d+$/) {
        $Request{status} = 404;
        return;
    }
    my $user = Act::User->new(
        user_id => $Request{args}{user_id},
        conf_id => $Request{conference},
    );
    unless ($user) {
        $Request{status} = 404;
        return;
    }
    # user logged in and registered
    if ($Request{args}{leave}) {
        # remove the participation to this conference
        my $sth = $Request{dbh}->prepare_cached(
            "DELETE FROM participations WHERE user_id=? AND conf_id=?"
        );
        $sth->execute($Request{args}{user_id}, $Request{conference});
        $sth->finish();
        $Request{dbh}->commit;
        return Act::Util::redirect(make_uri('payments'))
    }
    else {
        my $template = Act::Template::HTML->new();
        $template->variables(user => $user);
        $template->process('payment/unregister');
        return;
    }
}

1;

=head1 NAME

Act::Handler::Payment::Unregister - unregister a user from a conference

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
