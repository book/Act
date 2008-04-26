package Act::Handler::OpenID;

use strict;
use Apache::Constants qw(NOT_FOUND);
use Net::OpenID::Server;

use Act::Config;
use Act::User;
use Act::Util;
use URI::Escape;

my %actions = (
    openid => \&openid,
);

sub handler {
    my ($action, @args);
    $action = $Request{args}{action} || 'openid';

    unless (exists $actions{$action}) {
        $Request{status} = NOT_FOUND;
        return;
    }

    my $nos = Net::OpenID::Server->new(
        get_args      => $Request{r},
        post_args     => $Request{r},
        server_secret => sub { $_[0] },
        get_user      => sub { $Request{user} },
        is_identity   => sub { is_identity(@_) },
        is_trusted    => sub { is_trusted(@_) },
        setup_url     => ($Request{base_url} . make_uri('openid_trust')),
    );

    $actions{$action}->($nos, @args);
}

sub is_identity {
    my ($user, $identity_url) = @_;
    return 0 unless $user;
warn    my $author_url = $Request{base_url} . make_uri_info('user', $user->user_id);
    warn $identity_url;
    $author_url eq $identity_url;
}

sub is_trusted {
    my ($u, $trust_root, $is_identity) = @_;
    ## TODO: use saved trust too
    return 0 unless defined($u) && $is_identity;
    1;
}

sub openid {
    my($nos) = @_;

    my ($type, $data) = $nos->handle_page;
    if ($type eq "redirect") {
        Act::Util::redirect($data);
    } elsif ($type eq 'setup') {
        ## Was it an identity or trust failure? Cancel.
        return display_error('Your account is not authorized to assert the requested identity.')
            if $Request{user};

        my $url = $nos->setup_url;
        $url .= '?'.
            join('&', map { $_ .'='. URI::Escape::uri_escape($data->{$_}) }
                     qw( trust_root return_to identity assoc_handle ) );
        Act::Util::redirect($url);
    } else {
        $Request{r}->send_http_header($type);
        $Request{r}->print($data);
    }
}

sub display_error {
    $Request{r}->send_http_header('text/html;charset=UTF-8');
    $Request{r}->print($_[0]);
}

1;
