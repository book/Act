use strict;
package Act::Util;

use Apache::Constants qw(M_GET REDIRECT);
use Apache::AuthCookie;
use DateTime::Format::Pg;
use DBI;
use Digest::MD5 ();
use Text::Iconv ();
use URI::Escape ();

use Act::Config;

use vars qw(@ISA @EXPORT %Languages);
@ISA    = qw(Exporter);
@EXPORT = qw(make_uri make_uri_info self_uri localize);

# utf8 to latin1 converter
my $utf8_latin1 = Text::Iconv->new('UTF-8', 'ISO-8859-1');

# password generation data
my %grams = (
    v => [ qw( a ai e ia ou u o al il ol in on an ) ],
    c => [ qw( b bl br c ch cr chr dr f fr gu gr gl h j k kr ks kl
               m n p pr pl q qu r rh sb sc sf st sl sm sp tr ts v
               vr vl w x y z ) ],
);
my @pass = qw( vcvcvc cvcvcv cvcvc vcvcv );

# connect to the database
sub db_connect
{
    $Request{dbh} = DBI->connect_cached(
        $Config->database_dsn,
        $Config->database_user,
        $Config->database_passwd,
        { AutoCommit => 0,
          PrintError => 0,
          RaiseError => 1,
        }
    ) or die "can't connect to database: " . $DBI::errstr;
}

# create a uri for an action with args
sub make_uri
{
    my ($action, %params) = @_;

    my $uri = $Request{conference}
            ? join('/', '', $Config->uri, $action)
            : "/$action";
    return _build_uri($uri, %params);
}

# create a uri pathinfo-style
sub make_uri_info
{
    my ($action, $pathinfo) = @_;

    my $uri = $Request{conference}
            ? join('/', '', $Config->uri, $action)
            : "/$action";
    $uri .= "/$pathinfo" if $pathinfo;
    return $uri;
}

# self-referential uri with new args
sub self_uri
{
    return _build_uri($Request{r}->uri, @_);
}

sub _build_uri
{
    my ($uri, %params) = @_;

    if (%params) {
        $uri .= '?'
             . join '&',
               map "$_=" . URI::Escape::uri_escape($params{$_}),
               sort keys %params;
    }
    return $uri;
}

sub redirect
{
    my $location = shift;
    my $r = $Request{r} or return;
    if ($r->method eq 'POST') {
        $r->method("GET");
        $r->method_number(M_GET);
        $r->headers_in->unset("Content-length");
    }
    $r->headers_out->set(Location => $location);
    $r->status(REDIRECT);
    $r->send_http_header;
    return REDIRECT;
}

sub gen_password
{
    my $clear_passwd = $pass[ rand @pass ];
    $clear_passwd =~ s/([vc])/$grams{$1}[rand@{$grams{$1}}]/g;
    return ($clear_passwd, crypt_password( $clear_passwd ));
}

sub crypt_password
{
    my $digest = Digest::MD5->new;
    $digest->add(shift);
    return $digest->b64digest();
}
sub create_session
{
    my $user = shift;

    # create a session ID
    my $digest = Digest::MD5->new;
    $digest->add(rand(9999), time(), $$);
    my $sid = $digest->b64digest();
    $sid =~ s/\W/-/g;

    # save this user for the content handler
    $Request{user} = $user;
    $user->update(session_id => $sid, language => $Request{language});

    return $sid;
}
sub login
{
    my $user = shift;
    my $sid = create_session($user);
    Apache::AuthCookie->send_cookie($sid);
}

# datetime formatting suitable for display
sub date_format
{
    my ($s, $fmt) = @_;
    my $dt = ref $s ? $s : DateTime::Format::Pg->parse_timestamp($s);
    my $lang = $Request{language} || $Config->general_default_language;
    $dt->set(locale => $lang);
    return $utf8_latin1->convert($dt->strftime($Act::Config::Languages{$lang}{"fmt_$fmt"}));
}

# translate a string
sub localize
{
    return $Request{loc}->maketext($_[0]);
}
1;

__END__

=head1 NAME

Act::Util - Utility routines

=head1 SYNOPSIS

    $uri = make_uri("talkview", id => 234, name => 'foo');
    $uri = self_uri(language => 'en');
    ($clear, $crypted) = Act::Util::gen_passwd();

=head1 DESCRIPTION

Act::Util contains a collection of utility routines that didn't fit anywhere
else.

=over 4

=item make_uri(I<$action>, I<%params>)

Returns an URI that points to I<action>, with an optional query string
built from I<%params>. For more details on actions, refer to the
Act::Dispatcher documentation.

=item self_uri(I<%params>)

Returns a self-referential URI (a URI that points to the current location)
with an optional query string built from I<%params>. 

=item gen_passwd

Generates a password. Returns a two-element list with the password in
clear-text and encrypted forms.

=item localize

Translates a string according to the current request language.

=back

=cut
