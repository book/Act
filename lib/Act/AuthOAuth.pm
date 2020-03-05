package Act::AuthOAuth;

use strict;
use Apache::Constants qw(OK REDIRECT);

use Act::Config;
use Act::User;
use Act::Util;

use Act::TwoStep;

use JSON::XS;
use LWP::UserAgent;
use MIME::Base64;
use URI::Escape;

use base qw(Act::Auth);

sub oauth_login ($$) 
{
    my ( $self, $r ) = @_;

    my %args = $r->args;
    my $destination  = $args{destination};

    # Send AuthN Request
    my $authorization_uri = $Config->oauth2_authorizationuri;
    my $response_type = uri_escape("code");
    my $scope         = uri_escape("openid profile email");
    my $client_id    = uri_escape($Config->oauth2_clientid);
    my $redirect_uri = uri_escape($Config->oauth2_redirecturi);
    my $state = uri_escape($destination);

    my $redirect_url = $authorization_uri."?response_type=$response_type&client_id=$client_id&scope=$scope&redirect_uri=$redirect_uri&state=$state";

    $r->log_error("Redirect user to $redirect_url");

    $r->header_out('Location' => $redirect_url);

    return REDIRECT;
}

sub oauth_login_callback ($$)
{
    my ( $self, $r ) = @_;

    # AuthN Response
    my %args = $r->args;
    my $code  = $args{code};
    my $state  = $args{state};

    $r->log_error("Code received: $code");

    my $grant_type = "authorization_code";

    my %form;
    $form{"code"}          = $code;
    $form{"client_id"}     = $Config->oauth2_clientid;
    $form{"client_secret"} = $Config->oauth2_clientsecret;
    $form{"redirect_uri"}  = $Config->oauth2_redirecturi;
    $form{"grant_type"}    = $grant_type;

    $r->log_error("POST token request on ".$Config->oauth2_tokenuri);

    my $ua = new LWP::UserAgent;
    my $response = $ua->post( $Config->oauth2_tokenuri, \%form,
        "Content-Type" => 'application/x-www-form-urlencoded' );

    if ( $response->is_error ) {
        $r->log_error("Bad authorization response: " . $response->message);
        $r->log_error($response->content);
	return undef;
    }

    # Get access_token and id_token
    my $content = $response->decoded_content;

    my $json;
    eval { $json    = decode_json $content; };

    if ($@) {
        $r->log_error("Wrong JSON content");
	return undef;
    }

    if ( $json->{error} ) {
        $r->log_error("Error in token response:" . $json->{error});
	return undef;
    }

    my $access_token = $json->{access_token};
    my $id_token     = $json->{id_token};

    # Get ID token content
    my ( $id_token_header, $id_token_payload, $id_token_signature ) = split( /\./, $id_token );

    # TODO check JWT signature

    my $id_token_payload_hash = decode_json( decode_base64 ( $id_token_payload ) );

    # Get user email
    my $email = $id_token_payload_hash->{email};

    # Match with ACT user
    my $user = Act::User->new( email => lc $email );

    my $destination;

    if ($user) {
        $r->log_error("User found with email $email");

        # user is authenticated - create a session
        my $sid = Act::Util::create_session($user);

        $self->send_cookie($sid);

        $self->handle_cache;

        $destination = $state || "/";
    }

    # No corresponding account, redirect on register page
    my $token = Act::TwoStep->_create_token($email);
    my $data;
    my $sth = $Request{dbh}->prepare_cached('INSERT INTO twostep (token, email, datetime, data) VALUES (?, ?, NOW(), ?)');
    $sth->execute($token, $email, $data);
    $Request{dbh}->commit;

    $destination = "register/$token";

    $r->header_out("Location" => $destination);

    return REDIRECT;
}

1;

__END__

=head1 NAME

Act::AuthOAuth - OpenID Connect authentication backend for Act

=head1 SYNOPSIS

This module allows to log user on an OpenID Connect provider.

=head2 How it works

User click on a link on the login page and is redirected to OpenID Connect Provider. He must
accept to share his information with Act, and is then redirected back. If a user account with
the corresponding email is found in Act, the user is logged in. If not, he gets a register form.

=head2 Add the link

Edit templates/login file to add this link:
    <p><a href="OAUTHLOGIN?destination=[% destination %]">Log with your Google account</a></p>

=head2 Configure endpoints in Apache

Edit Act Apache configuration to add these 2 endpoints:

<Files OAUTHLOGIN>
  AuthType          Act::AuthOAuth
  AuthName          Act
  SetHandler        "perl-script"
  PerlHandler       Act::AuthOAuth->oauth_login
</Files>

<Files OAUTHLOGINCB>
  AuthType          Act::AuthOAuth
  AuthName          Act
  SetHandler        "perl-script"
  PerlHandler       Act::AuthOAuth->oauth_login_callback
</Files>

Do not forget to add at the top of the file:
PerlModule Act::AuthOAuth

=head2 Configure act.ini

Add this section to your act.ini file:
[oauth2]
clientid = [CLIENT_ID]
clientsecret = [CLIENT_SECRET]
redirecturi = http://[ACT_HOST]/[CONF]/OAUTHLOGINCB
authorizationuri = [AUTHORIZATION_ENDPOINT]
tokenuri = [TOKEN_ENDPOINT]

You need to register your Act application inside the OpenID Connect Provider to gather the
required configuration parameters.

=cut
