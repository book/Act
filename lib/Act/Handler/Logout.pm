package Act::Handler::Logout;

use strict;
use Act::Config;
use Act::Template::HTML;
use Act::Util;

sub handler
{
    my $r = $Request{r};

    # disable client-side caching
    $r->no_cache(1);

    # clear the session
    $Request{user}->update(session_id => undef);

    # remove the session cookie
    $r->auth_type->logout($r);

    # we're no longer authenticated
    undef $Request{user};

    # display the logout page
    my $template = Act::Template::HTML->new();
    $template->process('logout');
}
1;
__END__

=head1 NAME

Act::Handler::Logout - log out a user

=head1 DESCRIPTION

This handler logs out the currently logged in user

=cut
