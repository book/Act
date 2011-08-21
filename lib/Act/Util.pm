use strict;
use utf8;
package Act::Util;

use DateTime::Format::Pg;
use DBI;
use Digest::MD5 ();
use Unicode::Normalize ();
use URI::Escape ();

use Act::Config;
use Act::Database;

use vars qw(@ISA @EXPORT %Languages);
@ISA    = qw(Exporter);
@EXPORT = qw(make_uri make_uri_info self_uri localize);

# password generation data
my %grams = (
    v => [ qw( a ai e ia ou u o al il ol in on an ) ],
    c => [ qw( b bl br c ch cr chr dr f fr gu gr gl h j k kr ks kl
               m n p pr pl q qu r rh sb sc sf st sl sm sp tr ts v
               vr vl w x y z ) ],
);
my @pass = qw( vcvcvc cvcvcv cvcvc vcvcv );

# normalize() stuff
my (%ncache, %chartab);
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
        n => 'ļł',
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
# normalize() exceptions
my @normalize_exceptions = ( 'й' );

sub search_expression
{
    return join '', map { $chartab{$_} || $_ } split '', shift;
}
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
          pg_enable_utf8 => 1,
        }
    ) or die "can't connect to database: " . $DBI::errstr;

    # check schema version
    my ($version, $required) = Act::Database::get_versions($Request{dbh});
    if ($version > $required) {
        die "database schema version $version is too recent: this code runs version $required\n";
    }
    if ($version < $required) {
        die "database schema version $version is too old: version $required is required. Run bin/dbupdate\n";
    }
    return $Request{dbh};
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
               map "$_=" . URI::Escape::uri_escape_utf8($params{$_}),
               sort keys %params;
    }
    return $uri;
}

sub redirect
{
    my $location = shift;
    my $r = $Request{r} or return;
    $r->headers->header(Location => $location);
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
    my $dt = ref $s ? $s : DateTime::Format::Pg->parse_timestamp($s);
    my $lang = $Request{language} || $Config->general_default_language;
    my $variant = $Config->language_variants->{$lang} || $lang;
    $dt->set(locale => $variant);

    if ($variant =~ /^((\w+)_.*)$/) {    # $1 = en_US, $2 = en
        $variant = $2 unless exists $Act::Config::Languages{$variant};
    }

    return $dt->strftime($Act::Config::Languages{$variant}{"fmt_$fmt"} || $fmt);
}

# translate a string
sub localize
{
    return $Request{loc}->maketext(@_);
}

# normalize a string for sorting
sub normalize
{
    my $string = shift;
    return $ncache{$string} if exists $ncache{$string};
    my $copy = $string;
    $string = Unicode::Normalize::NFD($string);
    $string =~ s/\p{InCombiningDiacriticalMarks}//g;
    for my $chr (@normalize_exceptions) {
        my $pos = 0;
        while (($pos = index($copy, $chr, $pos)) >= 0) {
            substr($string, $pos, 1) = $chr;
            ++$pos;
        }
    }
    return $ncache{$string} = lc $string;
}

# unicode-aware string sort
sub usort(&@)
{
    my $code = shift;
    my $getkey = sub { local $_ = shift; $code->() };

    # use Unicode::Collate if allkeys.txt is installed
    eval {
        require Unicode::Collate;
        # new() dies if allkeys.txt isn't installed
        my $collator = Unicode::Collate->new();

        return map  { $_->[1] }
               sort { $collator->cmp( $a->[0], $b->[0] ) }
               map  { [ $getkey->($_), $_ ] }
               @_;
    };
    # fallback to normalize()
    return map  { $_->[1] }
           sort { $a->[0] cmp $b->[0] }
           map  { [ normalize($getkey->($_)), $_ ] }
           @_;
}

sub ua_isa_bot {
    $Request{r}->header_in('User-Agent') =~ /
      altavista
    | crawler
    | gigabot
    | googlebot
    | hatena
    | msnbot
    | infoseek
    | libwww-perl
    | lwp
    | lycos
    | spider
    | wget
    | yahoo
    /ix;
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
    my $lang = (split/::/, ref $self->locale)[-1];
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
by C<Unicode::Collate>. If the Unicode Collation Element Table is not
installed, C<usort> falls back to comparing normalized strings.

=item ua_isa_bot

Return a true value is the client User-Agent string gives it away as
a robot.

=back

=cut
