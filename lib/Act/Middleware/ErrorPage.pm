package Act::Middleware::ErrorPage;
# ABSTRACT: Provide customized error pages
use warnings;
use strict;

use parent qw(Plack::Middleware);
use Plack::Util;
use Act::Template::HTML;


sub call {
    my $self = shift;
    my $env = shift;


    my $response = $self->app->($env);

    # Use a closure to get $env forwarded to the post processor
    return Plack::Util::response_cb($response,
                                    sub { return _create_body($env,@_); }
                                   );
}


sub _create_body {
    my ($env,$response) = @_;

    my $path_info = $env->{PATH_INFO};
    my $accept    = $env->{HTTP_ACCEPT} || '*/*';

    my ($code,$headers,$old_body) = @$response;

    return $response   if ($code != 404);
    return $response   if (! _is_html_acceptable($accept));

    my $body;
    my $template = Act::Template::HTML->new;
    $template->variables(path_info => $path_info);
    $template->process('error404',\$body);
    utf8::encode($body);
    Plack::Util::header_set($headers,
                            'Content-Type',
                            'text/html; charset=UTF-8');
    Plack::Util::header_set($headers,
                            'Content-Length',
                            length $body);
    $response->[2] = [$body];
    return $response;
}


sub _is_html_acceptable {
    my ($accept) = @_;
    my @types = split /\s*,\s*/,$accept;
    for my $type (@types) {
        return 1 if $type =~ m!^text/html\s*(;|$) |     # text/html
                               ^\Qtext/*\E\s*(;|$) |    # text/*
                               ^\Q*/*\E\s*(;|$)         # */*
                              !x;
    }
    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Act::Middleware::ErrorPage - Provide customized error pages

=head1 SYNOPSIS

   $mw->call($env); # as by the Plack application

=head1 DESCRIPTION

This middleware component post-processes the Plack response.  In case
of an error (only 404 is implemented), it replaces the body with a
processed HTML template - but only if text/html is accepted by the
client.

=head1 METHODS

=head2 $mw->call($env)

As required by L<Plack::Middleware>.

=head2 _create_body ($env,$response)

Injects a body from a template into the PSGI response, using the
L<Act::Template::HTML> infrastructure.

=head2 _is_html_acceptable($accept)

Returns true if the parameter (which is the value of a HTTP Accept
header) allows a response of text/html.

=head1 RESTRICTIONS

Right now, this middleware is injected at a stage where the Act
configuration has not yet been read and where the database has not yet
been connected.  Therefore, neither the configuration nor database
contents are available, and there's no Act infrastructure for
translations.

=head1 AUTHOR

Harald Jörg, <haj@posteo.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.
