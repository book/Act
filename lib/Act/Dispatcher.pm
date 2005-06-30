use strict;
package Act::Dispatcher;

use Apache::Constants qw(:common);
use Apache::Cookie ();
use Apache::Request;
use DBI;

use Act::Config;
use Act::User;
use Act::Util;

use constant DEFAULT_PAGE => 'index.html';

# main dispatch table
my %dispatch = (
    # regular handlers
    login    => { handler => 'Act::Handler::Login' },
    search   => { handler => 'Act::Handler::User::Search' },
    register => { handler => 'Act::Handler::User::Register' },
    user     => { handler => 'Act::Handler::User::Show' },
    resetpw  => { handler => 'Act::Handler::User::ResetPassword' },
    stats    => { handler => 'Act::Handler::User::Stats' },
    talk     => { handler => 'Act::Handler::Talk::Show' },
    talks    => { handler => 'Act::Handler::Talk::List' },
    event    => { handler => 'Act::Handler::Event::Show' },
    events   => { handler => 'Act::Handler::Event::List' },
    schedule => { handler => 'Act::Handler::Talk::Schedule' },
    'timetable.ics' => { handler => 'Act::Handler::Talk::Export' },

    # protected handlers
    unregister => { handler => 'Act::Handler::User::Unregister', private => 1 },
    logout   => { handler => 'Act::Handler::Logout',         private => 1 },
    main     => { handler => 'Act::Handler::User::Main',     private => 1 },
    change   => { handler => 'Act::Handler::User::Change',   private => 1 },
    export   => { handler => 'Act::Handler::User::Export',   private => 1 },
    photo    => { handler => 'Act::Handler::User::Photo',    private => 1 },
    purchase => { handler => 'Act::Handler::User::Purchase', private => 1 },
    rights   => { handler => 'Act::Handler::User::Rights',   private => 1 },
    newtalk  => { handler => 'Act::Handler::Talk::Edit',   private => 1 },
    edittalk => { handler => 'Act::Handler::Talk::Edit',   private => 1 },
    newevent  => { handler => 'Act::Handler::Event::Edit',  private => 1 },
    editevent => { handler => 'Act::Handler::Event::Edit',  private => 1 },
    ical_import => { handler => 'Act::Handler::Talk::Import',   private => 1 },
    payment   => { handler => 'Act::Handler::Payment::Payment', private => 1 },
    payments  => { handler => 'Act::Handler::Payment::List',   private => 1 },
    invoice   => { handler => 'Act::Handler::Payment::Invoice', private => 1 },
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
        base_url  => _base_url($r),
    );
    
    # connect to database
    Act::Util::db_connect();

    # URI must start with a conf name
    unless (@c && (exists $Config->uris->{$c[0]} || exists $Config->conferences->{$c[0]})) {
        return DECLINED;
    }
    # set the correct configuration
    $Request{conference} = $Config->uris->{$c[0]} || $c[0];
    shift @c;
    $Request{path_info}  = join '/', @c;
    $Config = Act::Config::get_config($Request{conference});

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
    $Request{args} = { map { $_ => $r->param($_) || '' } $r->param };
    _set_language();

    # redirect language change requests
    if (delete $Request{args}{language}) {
        return Act::Util::redirect(self_uri(%{$Request{args}}));
    }
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

    return $Request{status} || OK;
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
            -path    =>  '/',
        );
        $cookie->bake;
    }
}

sub _base_url
{
    my $r = shift;
    my $url = 'http://' . $r->server->server_hostname;
    $url .= ':' . $r->server->port if $r->server->port != 80;
    return $url;
}

1;
__END__

=head1 NAME

Act::Dispatcher - Dispatch web request

=head1 SYNOPSIS

No user-serviceable parts. Warranty void if open.

=cut
