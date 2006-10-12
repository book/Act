package Act::Auth;

use strict;
use Apache::AuthCookie;
use Apache::Constants qw(OK);
use Digest::MD5 ();

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
    my ($self, $r, $login, $sent_pw) = @_;

    # error message prefix
    my $prefix = join ' ', map { "[$_]" }
        $r->server->server_hostname,
        $r->connection->remote_ip,
        $login,
        $sent_pw;

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
    my $digest = Digest::MD5->new;
    $digest->add(lc $sent_pw);
    $digest->b64digest() eq $user->{passwd}
        or do { $r->log_error("$prefix Bad password"); return undef; };

    # user is authenticated - create a session
    my $sid = Act::Util::create_session($user);

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

sub _update_language
{
    $Request{user}->update(language => $Request{language})
        unless defined($Request{user}->{language})
            && $Request{language} eq $Request{user}->{language};
}

1;
__END__

=head1 NAME

Act::Auth - authentication handler and callbacks

=head1 SYNOPSIS

See F<INSTALL> and F<conf/httpd.conf>

=cut
