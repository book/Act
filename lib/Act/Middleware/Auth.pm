package Act::Middleware::Auth;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Request;
use Act::Config ();
use Try::Tiny;
use Plack::Util::Accessor qw(private);

sub call {
    my $self = shift;
    my $env = shift;

    my $req = Plack::Request->new($env);

    if ($req->path_info eq 'LOGIN' || $req->path_info eq '/LOGIN') {
        return $self->check_login($req);
    }

    my $session_id = $req->cookies->{'Act_session_id'};

    $env->{'act.auth.login'} = \&_login;
    $env->{'act.auth.logout'} = \&_logout;
    $env->{'act.auth.set_session'} = \&_set_session;

    my $user;
    if(defined $session_id) {
        $user = Act::User->new( session_id => $session_id );
    }

    if ($user) {
        $env->{'act.user'} = $user;
    }
    elsif ($self->private) {
        return Act::Handler::Login->new->call($env);
    }
    $self->app->($env);
}

sub _login {
    my $resp = shift;
    my $user = shift;
    my $sid = Act::Util::create_session($user);
    $resp->cookies->{'Act_session_id'} = {
        value => $sid,
        expires => 1,
    };
}
sub _logout {
    my $resp = shift;
    $resp->cookies->{'Act_session_id'} = {
        value => '',
        expires => 1,
    };
}
sub _set_session {
    my $resp = shift;
    my $sid = shift;
    my $remember_me = shift;
    $resp->cookies->{Act_session_id} = {
        value => $sid,
        $remember_me ? ( expires => time + 6*30*24*60*60 ) : (),
    };
}

sub check_login {
    my $self = shift;
    my $req = shift;

    my $params = $req->parameters;

    my $login   = $params->get('login');
    my $sent_pw = $params->get('password');
    my $remember_me = $params->get('remember_me');
    my $dest    = $params->get('destination');

    # remove leading and trailing spaces
    for ($login, $sent_pw) {
        s/^\s*//;
        s/\s*$//;
    }

    return try {
        # login and password must be provided
        $login
            or die ["No login name"];
        $sent_pw
            or die ["No password"];

        # search for this user in our database
        my $user = Act::User->new( login => lc $login );
        $user
            or die ["Unknown user"];

        try {
            $user->check_password($sent_pw);
        }
        catch {
            die ['Bad password'];
        };

        # user is authenticated - create a session
        my $sid = Act::Util::create_session($user);
        my $resp = Plack::Response->new;
        $resp->redirect($dest);
        _set_session($resp, $sid, $remember_me);
        return $resp->finalize;
    }
    catch {
        my $env = $req->env;

        my $error = $_->[0];
        my $full_error = join ' ', map { "[$_]" }
            $env->{SERVER_NAME},
            $req->address,
            $login,
            $error;

        $req->logger->({ level => 'error', $full_error });

        $env->{'act.login.destination'} = $dest;
        $env->{'act.login.error'} = 1;
        return Act::Handler::Login->new->call($env);
    };
}

1;

