use strict;
use utf8;
package Act::Util;

use Act::Config;
use Act::Store::Database;
use DBI;
use DateTime::Format::HTTP;
use Digest::MD5 ();
use Try::Tiny;
use URI::Escape ();
use Unicode::Normalize ();
use Unicode::Collate;

use vars qw(@ISA @EXPORT @EXPORT_OK %Languages);
@ISA    = qw(Exporter);
@EXPORT = qw(make_uri make_abs_uri make_uri_info self_uri localize format_datetime_string);

@EXPORT_OK = qw (
    usort
);

# password generation data
my %grams = (
    v => [ qw( a ai e ia ou u o al il ol in on an ) ],
    c => [ qw( b bl br c ch cr chr dr f fr gu gr gl h j k kr ks kl
               m n p pr pl q qu r rh sb sc sf st sl sm sp tr ts v
               vr vl w x y z ) ],
);
my @pass = qw( vcvcvc cvcvcv cvcvc vcvcv );

# normalize() stuff
my (%chartab);
BEGIN {
    my %accents = (
        a => 'àáâãäåȧāą',
        c => 'çć',
        d => 'ḑ',
        e => 'èéêëēęȩ',
        g => 'ģğ',
        h => 'ḩ',
        i => 'ìíîïī',
        k => 'ķ',
        l => 'ļł',
        n => 'ñńņ',
        o => 'òóôõöőōð',
        r => 'ŕřŗ',
        s => 'šśş',
        t => 'ťţ',
        u => 'ùúûüűųūů',
        y => 'ýÿ',
        z => 'źżżž',
    );
    # build %chartab for search_expression()
    while (my ($letter, $accented) = each %accents) {
        my @accented = split '', $accented;
        my $cclass = '[' . $letter . uc($letter) . join('', @accented, map uc, @accented) . ']';
        $chartab{$_} = $cclass for ($letter, uc($letter), @accented);
    }
}

sub search_expression
{
    return join '', map { $chartab{$_} || $_ } split '', shift;
}

# TODO: Move to Act::Database?
# -- haj 2020-04-28: We keep the connection here for the moment.
#    Act relies on  AutoCommit => 0, which is not the recommended
#    way with DBIx::Class.
# connect to the database
sub db_connect
{
    my $dsn = $Config->database_dsn;
    if ($Config->database_host) {
        $dsn .= ";host=" . $Config->database_host;
    }

    $Request{dbh} = DBI->connect_cached(
        $dsn,
        $Config->database_user,
        $Config->database_passwd,
        { AutoCommit => 0,
          PrintError => 0,
          RaiseError => 1,
          pg_enable_utf8 => 1,
        }
    ) or die "can't connect to database: " . $DBI::errstr;

    # check schema version
    if ($Config->database_version_check // 1) {
        Act::Store::Database->instance->_check_db_version();
    }
    return $Request{dbh};
}

sub format_datetime_string {
    my $string = shift;

    # TODO: Maybe use bless and check for DT object?
    return $string if ref($string);
    return try {
        return  DateTime::Format::HTTP->parse_datetime($string);
    }
    catch {
        warn "Unable to parse $string to datetime\n";
        die $_;
    };
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

sub make_abs_uri {
    my ( $action, %params ) = @_;

    my $uri = $Request{r}->uri;
    $uri->path(make_uri(@_));
    return $uri;
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
               map "$_=" . URI::Escape::uri_escape_utf8($params{$_}),
               sort keys %params;
    }
    return $uri;
}

sub redirect
{
    my $location = shift;
    my $r = $Request{r} or return;
    $r->response->headers->header(Location => $location);
    $r->response->status(302);
    $r->send_http_header;
    return 302;
}

sub gen_password
{
    my $clear_passwd = $pass[ rand @pass ];
    $clear_passwd =~ s/([vc])/$grams{$1}[rand@{$grams{$1}}]/g;
    return $clear_passwd;
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
sub get_user_info
{
    return undef unless $Request{user};
    return {
        email => $Request{user}->email,
        time_zone => $Request{user}->timezone,
    };
}

# datetime formatting suitable for display
sub date_format
{
    my ($s, $fmt) = @_;
    my $dt = format_datetime_string($s);

    my $lang = $Request{language} || $Config->general_default_language;
    my $variant = $Config->language_variants->{$lang} || $lang;
    $dt->set_locale($variant);

    if ($variant =~ /^((\w+)_.*)$/) {    # $1 = en_US, $2 = en
        $variant = $2 unless exists $Act::Config::Languages{$variant};
    }

    return $dt->strftime($Act::Config::Languages{$variant}{"fmt_$fmt"} || $fmt);
}

=head2 localize

Localize a text, returns the original input if nothing can be localized (Request->{loc} is missing).

=cut

sub localize {
    return $Request{loc}->maketext(@_) if defined $Request{loc};
    #    require Carp;
    #    Carp::cluck("no Request{loc} to be found");
    return join("$/", @_);
}

# unicode-aware string sort
sub usort(&@)
{
    my $code = shift;
    my $getkey = sub { local $_ = shift; $code->() };

    my $collator = Unicode::Collate->new();

    return map  { $_->[1] }
        sort { $collator->cmp( $a->[0], $b->[0] ) }
        map  { [ $getkey->($_), $_ ] }
        @_;
}


sub ua_isa_bot {
    $Request{r}->header_in('User-Agent') =~ m!
      # altavista # out of service since 2003
      crawler
    | gigabot
    | googlebot
    | hatena
    | ltx71       # http://ltx71.com/ - claims to be "security checking"
    | mj12bot     # http://mj12bot.com/; https://majestic.com/
    | msnbot
    | netsystemsresearch # netsystemsresearch.com - claims "security"
    | infoseek
    | libwww-perl
    | lwp
    | lycos
    | pdrlabs     # http://www.pdrlabs.net "Internet Mapping Experiment"
    | spider
    | wget
    | yahoo
    !ix;
}

use DateTime;
package DateTime;

my %genitive_monthnames = (
    be => [ "студзеня",
            "лютага",
            "сакавіка",
            "красавіка",
            "мая",
            "чэрвеня",
            "ліпеня",
            "жніўеня",
            "верасня",
            "кастрычніка",
            "лістапада",
            "снежня",
          ],
    ru => [ "января",
            "февраля",
            "марта",
            "апреля",
            "мая",
            "июня",
            "июля",
            "августа",
            "сентября",
            "октября",
            "ноября",
            "декабря"
          ],
    sk => [ "Januára",
            "Februára",
            "Marca",
            "Apríla",
            "Mája",
            "Júna",
            "Júla",
            "Augusta",
            "Septembra",
            "Októbra",
            "Novembra",
            "Decembra"
          ],
    uk => [ 
            "січня",
            "лютого",
            "березня",
            "квітня",
            "травня",
            "червня",
            "липня",
            "серпня",
            "вересня",
            "жовтня",
            "листопада",
            "грудня",
          ],
);

sub genitive_month
{
    my $self = shift;
    my $lang = $self->locale->language_id;
    return exists $genitive_monthnames{$lang}
                ? $genitive_monthnames{$lang}[$self->month_0]
                : undef;
}

1;

__END__

=head1 NAME

Act::Util - Utility routines

=head1 SYNOPSIS

    $uri = make_uri("talkview", id => 234, name => 'foo');
    $uri = self_uri(language => 'en');
    ($clear, $crypted) = Act::Util::gen_passwd();
    my $localized_string = localize('some_string_id');
    my @sorted = Act::Util::usort { $_->{last_name} } @users;

=head1 DESCRIPTION

Act::Util contains a collection of utility routines that didn't fit anywhere
else.

=over 4

=item make_uri(I<$action>, I<%params>)

Returns an URI that points to I<action>, with an optional query string
built from I<%params>. For more details on actions, refer to the
Act::Dispatcher documentation.

=item make_abs_uri(I<$action>, I<%params>)

Similar to L<make_uri/"">, but returns an absolute URI.

=item self_uri(I<%params>)

Returns a self-referential URI (a URI that points to the current location)
with an optional query string built from I<%params>. 

=item gen_passwd

Generates a password. Returns a two-element list with the password in
clear-text and encrypted forms.

=item localize

Translates a string according to the current request language.

=item normalize

Normalizes a string for sorting: removes diacritical marks and converts
to lowercase.

=item usort

Sorts a list of strings with correct Unicode semantics, as provided
by C<Unicode::Collate>.

=item ua_isa_bot

Return a true value is the client User-Agent string gives it away as
a robot.

I<Note:> As of 2020-02-21, this subroutine is not being called from
anywhere within the codebase.  It will be eliminated unless some use
case comes up.

=back

=cut
