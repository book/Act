package Act::Middleware::Auth;
# ABSTRACT: Check whether we have or need authentication
use strict;
use warnings;

use Act::User;

use parent qw(Plack::Middleware);
use Plack::Session;
use Plack::Util::Accessor qw(private);

sub call {
    my $self = shift;
    my $env = shift;

    my $session = Plack::Session->new($env);
    my $login   = $session->get('login');
    $env->{'act.loginuser'} = $login;

    if (! $login  && $self->private) {
        $env->{'act.login.destination'} = $env->{REQUEST_URI};
        return Act::Handler::Login->new->call($env);
    }

    $login  and  $env->{'act.user'} = Act::User->new( login => $login );
    $self->app->($env);
}

1;

__END__

=encoding utf8

=head1 NAME

Act::Middleware::Auth - Check whether we have or need authentication

=head1 SYNOPSIS

in your Builder:

    enable '+Act::Middleware::Auth'

=head1 DESCRIPTON

This Plack middleware component checks whether we are in a session (as
provided by L<Plack::Session>), and whether this session is
authenticated.  If the session isn't authenticated, but the request
needs authentication, this component interrupts the workflow and
redirects to the login screen handler L<Act::Handler::Login>.  The
current request URL is passed in the environment so that the login
handler can resume the workflow.

=head1 AUTHOR

Graham Knop and Rob Hoelz wrote the initial version, most of which has
been moved to other places by now.

=head1 CURRENT MAINTAINER

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2001 Graham Knop, Rob Hoelz

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
