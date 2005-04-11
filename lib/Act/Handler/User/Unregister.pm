package Act::Handler::User::Unregister;

use Act::Template::HTML;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    # not registered!
    return Act::Util::redirect(make_uri('main'))
      unless $Request{user}->has_registered;

    # committed users can't unregister like this
    return Act::Util::redirect(make_uri('main'))
      if $Request{user}->has_talk || $Request{user}->has_paid;
   
    # user logged in and registered
    if ($Request{args}{leave}) {
        # remove the participation to this conference
        my $sth = $Request{dbh}->prepare_cached(
            "DELETE FROM participations WHERE user_id=? AND conf_id=?"
        );
        $sth->execute($Request{user}->user_id, $Request{conference});
        $sth->finish();
        $Request{dbh}->commit;
        return Act::Util::redirect(make_uri('main'))
    }
    else {
        my $template = Act::Template::HTML->new();
        $template->process('user/unregister');
        return;
    }
}

1;

=head1 NAME

Act::Handler::User::Unregister - unregister a user from a conference

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
