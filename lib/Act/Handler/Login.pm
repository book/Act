package Act::Handler::Login;

use strict;
use Apache::Constants qw(DONE);
use Act::Config;
use Act::Template::HTML;
use Act::Util;

sub handler
{
    my $r = $Request{r};

    # disable client-side caching
    $r->no_cache(1);

    # process the login form template
    my $template = Act::Template::HTML->new();
    $template->variables(
        destination => $r->prev && $r->prev->uri ? $r->prev->uri : '/',
        action      => Act::Util::make_uri('LOGIN'),
    );
    $template->process('login');
    $Request{status} = DONE;
}
1;
__END__

=head1 NAME

Act::Handler::Login - display the login form

=head1 DESCRIPTION

This is automatically called by Act::Auth when access to
the requested page requires authentication.

=cut
