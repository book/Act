use strict;
package Act::Dispatcher;

use Apache::Constants qw(OK DECLINED);
use Apache::Cookie ();
use DBI;

use Act::Config;

use constant DEFAULT_PAGE => 'index.html';

# main dispatch table
my %dispatch = (
    coucou => sub {
        my $sth = $Request{dbh}->prepare('SELECT NOW()');
        $sth->execute();
        my ($now) = $sth->fetchrow_array();
        $Request{r}->send_http_header('text/plain');
        $Request{r}->print("$now - conférence ", $Request{conference});
    },
);

# translation handler
sub trans_handler
{
    # the Apache request object
    my $r = shift;

    # break it up in components
    my @c = grep $_, split '/', $r->uri;

    # initialize our per-request variables
    %Request = (
        r         => $r,
        args      => { $r->args },
        path_info => join('/', @c),
    );
    # see if URI starts with a conf name
    if (@c && exists $Config->conferences->{$c[0]}) {
        $Request{conference} = shift @c;
        $Request{path_info}  = join '/', @c;
    }
    # set the correct configuration
    $Config = Act::Config::get_config($Request{conference});

    # per-request initialization now that we have $Config
    _set_language();
    _db_connect();

    # default pages à la mod_dir
    if (!@c && $r->uri =~ m!/$!) {
        $r->uri(  $Request{conference}
                ? join('/', undef, $Request{conference}, DEFAULT_PAGE)
                : join('/', undef, DEFAULT_PAGE)
        );
        $Request{path_info} = DEFAULT_PAGE;
    }
    # pseudo-static pages
    if ($r->uri =~ /\.html$/) {
        $r->push_handlers(PerlHandler => 'Act::Static');
        return OK;
    }
    # we're looking for /x/y where
    # x is a conference name, and
    # y is an action key in %dispatch
    if (@c && $Request{conference} && exists $dispatch{$c[0]}) {
        $Request{action}     = shift @c;
        $Request{path_info}  = join '/', @c;
        $r->push_handlers(PerlHandler => 'Act::Dispatcher');
        return OK;
    }
    return DECLINED;
}

# response handler - it all starts here.
sub handler
{
    # the Apache request object
    $Request{r} = shift;

    # dispatch
    $dispatch{$Request{action}}->();

    return OK;
}

sub _set_language
{
    my $language = undef;
    my $sendcookie = 1;

    # see if we have a cookie
    my $cookie_name = $Config->general_cookie_name;
    my $cookies = Apache::Cookie->fetch;
    if (my $c = $cookies->{$cookie_name}) {
        my %v = $c->value;
        if ($v{language} && $Config->languages->{$v{language}}) {
            $language = $v{language};
            $sendcookie = 0;
        }
    }

    # language override supplied in query string
    my $force_language = $Request{args}{language};
    if ($force_language && $Config->languages->{$force_language}) {
        $sendcookie = $force_language ne $language;
        $language = $force_language;
    }

    # otherwise try one of the browser's languages
    unless ($language) {
        my $h = $Request{r}->header_in('Accept-Language') || '';
        for (split /,/, $h) {
            s/;.*$//;
            s/-.*$//;
            if ($_ && $Config->languages->{$_}) {
                $language = $_;
                $sendcookie = 1;
                last;
            }
        }
    }
    # last resort, use our default language
    $language ||= $Config->general_default_language;

    # remember it for this request
    $Request{language} = $language;

    # send the cookie if needed
    if ($sendcookie) {
        my $cookie = Apache::Cookie->new(
        $Request{r},
            -name    =>  $cookie_name,
            -value   =>  { language => $language },
            -expires =>  '+6M',
            -domain  =>  $Request{r}->server->server_hostname,
            -path    =>  '/',
        );
        $cookie->bake;
    }
}

sub _db_connect
{
    $Request{dbh} = DBI->connect(
        $Config->database_dsn,
        $Config->database_user,
        $Config->database_passwd,
        { AutoCommit => 0,
          PrintError => 0,
          RaiseError => 1,
        }
    ) or die "can't connect to database: " . $DBI::errstr;
    $Request{r}->register_cleanup( sub { $Request{dbh}->disconnect } );
}
1;
