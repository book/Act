use strict;
package Act::Dispatcher;

use Apache::Constants qw(:common);
use Apache::Cookie ();
use Apache::Request;
use DBI;

use Act::Config;
use Act::Util;

use constant DEFAULT_PAGE => 'index.html';

# main dispatch table
my %dispatch = (
    # regular handlers
    search   => { handler => 'Act::Handler::User::Search' },
    register => { handler => 'Act::Handler::User::Register' },
    user     => { handler => 'Act::Handler::User::Show' },
    stats    => { handler => 'Act::Handler::User::Stats' },
    
    # protected handlers
    main     => { handler => 'Act::Handler::User::Main',     private => 1 },
    change   => { handler => 'Act::Handler::User::Change',   private => 1 },
    photo    => { handler => 'Act::Handler::User::Photo',    private => 1 },
    newtalk  => { handler => 'Act::Handler::Talk::Register', private => 1 },

    # special stuff
    login    => { handler => 'Act::Handler::Login', status => DONE },
    logout   => { handler => 'Act::Handler::Logout', private => 1 },
);

# translation handler
sub trans_handler
{
    # the Apache request object
    my $r = Apache::Request->instance(shift);

    # break it up in components
    my @c = grep $_, split '/', $r->uri;

    # initialize our per-request variables
    %Request = (
        r         => $r,
        path_info => join('/', @c),
    );
    # see if URI starts with a conf name
    if (@c && exists $Config->conferences->{$c[0]}) {
        $Request{conference} = shift @c;
        $Request{path_info}  = join '/', @c;
    }
    # set the correct configuration
    $Config = Act::Config::get_config($Request{conference});
    _db_connect();

    # default pages à la mod_dir
    if (!@c && $r->uri =~ m!/$!) {
        $r->uri(Act::Util::make_uri(DEFAULT_PAGE));
        $Request{path_info} = DEFAULT_PAGE;
    }
    # pseudo-static pages
    if ($r->uri =~ /\.html$/) {
        return _dispatch($r, 'Act::Handler::Static');
    }
    # we're looking for /x/y where
    # x is a conference name, and
    # y is an action key in %dispatch
    elsif (@c && $Request{conference} && exists $dispatch{$c[0]}) {
        $Request{action}     = shift @c;
        $Request{path_info}  = join '/', @c;
        $Request{private} = $dispatch{$Request{action}}{private};
        return _dispatch($r, 'Act::Dispatcher');
    }
    return DECLINED;
}

sub _dispatch
{
    my ($r, $handler) = @_;

    # per-request initialization
    $Request{args} = { map { $_ => $r->param($_) } $r->param };
    _set_language();

    # set up content handler
    $r->handler("perl-script");
    $r->push_handlers(PerlHandler => $handler);
    return OK;
}    

# response handler - it all starts here.
sub handler
{
    # the Apache request object
    $Request{r} = Apache::Request->instance(shift);

    # dispatch
    if( ref $dispatch{$Request{action}}{handler} eq 'CODE' ) {
        $dispatch{$Request{action}}{handler}->();
    }
    else {
        eval "require $dispatch{$Request{action}}{handler};";
        die "require $dispatch{$Request{action}}{handler} failed!" if $@;
        $dispatch{$Request{action}}{handler}->handler();
    }

    return $dispatch{$Request{action}}{status} || OK;
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
__END__

=head1 NAME

Act::Dispatcher - Dispatch web request

=head1 SYNOPSIS

No user-serviceable parts. Warranty void if open.

=cut
