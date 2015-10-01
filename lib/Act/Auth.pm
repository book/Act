package Act::Auth;

use strict;
use Apache::AuthCookie;
use Apache::Constants qw(OK);

use Act::Config;
use Act::User;
use Act::Util;

use base qw(Apache::AuthCookie);

sub access_handler ($$)
{
    my ($self, $r) = @_;

    # set correct login script url
    $r->dir_config(ActLoginScript => join('/', '', $Request{conference}, 'login'));

    # disable authentication unless required
    # (Apache doesn't let us do it the other way around)
    if ($Request{private}) {

        # don't recognize_user
        $r->set_handlers(PerlFixupHandler  => [\&OK]);
    }
    else {
        $r->set_handlers(PerlAuthenHandler => [\&OK]);
    }
    return OK;
}
sub authen_cred ($$\@)
{
    my ($self, $r, $login, $sent_pw, $remember_me) = @_;

    # error message prefix
    my $prefix = join ' ', map { "[$_]" }
        $r->server->server_hostname,
        $r->connection->remote_ip,
        $login;

    # remove leading and trailing spaces
    for ($login, $sent_pw) {
        s/^\s*//;
        s/\s*$//;
    }

    # login and password must be provided
    $login   or do { $r->log_error("$prefix No login name"); return undef; };
    $sent_pw or do { $r->log_error("$prefix No password");   return undef; };

    # search for this user in our database
    my $user = Act::User->new( login => lc $login );
    $user or do { $r->log_error("$prefix Unknown user"); return undef; };

    # compare passwords
    Act::Util::verify_password(lc $sent_pw, $user->{passwd})
        or do { $r->log_error("$prefix Bad password"); return undef; };

    # user is authenticated - create a session
    my $sid = Act::Util::create_session($user);

    # remember remember me
    $r->pnotes(remember_me => $remember_me);
    return $sid;
}

sub authen_ses_key ($$$)
{
    my ($self, $r, $sid) = @_;

    # search for this user in our database
    my $user = Act::User->new( session_id => $sid );

    # unknown session id
    return () unless $user;

    # save this user for the content handler
    $Request{user} = $user;
    _update_language();

    return ($user->{login});
}

sub send_cookie
{
    my ($self, $ses_key, $cookie_args) = @_;
    my $r = Apache->request();

    # add expiration date if "remember me" was checked
    # unless an expiration is already set (logout)
    if (   !($cookie_args && exists $cookie_args->{expires})
        && $r->pnotes('remember_me') )
    {
        $cookie_args ||= {};
        $cookie_args->{expires} = '+6M';
    }
    $self->SUPER::send_cookie($ses_key, $cookie_args);
}

sub _update_language
{
    $Request{user}->update(language => $Request{language})
      if $Request{language} && $Request{user}->language ne $Request{language};
}

1;
__END__

=head1 NAME

Act::Auth - authentication handler and callbacks

=head1 SYNOPSIS

See F<INSTALL> and F<conf/httpd.conf>

=cut
