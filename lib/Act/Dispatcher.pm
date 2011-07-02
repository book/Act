use strict;
package Act::Dispatcher;

use Apache::Constants qw(:common);
use Apache::Cookie ();
use Apache::Request;
use DBI;
use Encode qw(decode_utf8);

use Act::Config;
use Act::I18N;
use Act::User;
use Act::Util;

use constant DEFAULT_PAGE => 'index.html';

# main dispatch table
my %public_handlers = (
    api             => 'Act::Handler::WebAPI',
    atom            => 'Act::Handler::News::Atom',
    changepwd       => 'Act::Handler::User::ChangePassword',
    event           => 'Act::Handler::Event::Show',
    events          => 'Act::Handler::Event::List',
    faces           => 'Act::Handler::User::Faces',
    favtalks        => 'Act::Handler::Talk::Favorites',
    login           => 'Act::Handler::Login',
    news            => 'Act::Handler::News::List',
    openid          => 'Act::Handler::OpenID',
    register        => 'Act::Handler::User::Register',
    schedule        => 'Act::Handler::Talk::Schedule',
    search          => 'Act::Handler::User::Search',
    stats           => 'Act::Handler::User::Stats',
    talk            => 'Act::Handler::Talk::Show',
    talks           => 'Act::Handler::Talk::List',
    'timetable.ics' => 'Act::Handler::Talk::ExportIcal',
    user            => 'Act::Handler::User::Show',
    wiki            => 'Act::Handler::Wiki',
);
my %private_handlers = (
    change          => 'Act::Handler::User::Change',
    create          => 'Act::Handler::User::Create',
    csv             => 'Act::Handler::CSV',
    confirm_attend  => 'Act::Handler::User::ConfirmAttendance',
    editevent       => 'Act::Handler::Event::Edit',
    edittalk        => 'Act::Handler::Talk::Edit',
    export          => 'Act::Handler::User::Export',
    export_talks    => 'Act::Handler::Talk::ExportCSV',
    ical_import     => 'Act::Handler::Talk::Import',
    invoice         => 'Act::Handler::Payment::Invoice',
    logout          => 'Act::Handler::Logout',
    main            => 'Act::Handler::User::Main',
    myschedule      => 'Act::Handler::Talk::MySchedule',
    'myschedule.ics'=> 'Act::Handler::Talk::ExportMyIcal',
    newevent        => 'Act::Handler::Event::Edit',
    newsadmin       => 'Act::Handler::News::Admin',
    newsedit        => 'Act::Handler::News::Edit',
    newtalk         => 'Act::Handler::Talk::Edit',
    orders          => 'Act::Handler::User::Orders',
    openid_trust    => 'Act::Handler::OpenID::Trust',
    payment         => 'Act::Handler::Payment::Edit',
    payments        => 'Act::Handler::Payment::List',
    photo           => 'Act::Handler::User::Photo',
    punregister     => 'Act::Handler::Payment::Unregister',
    purchase        => 'Act::Handler::User::Purchase',
    rights          => 'Act::Handler::User::Rights',
    trackedit       => 'Act::Handler::Track::Edit',
    tracks          => 'Act::Handler::Track::List',
    updatemytalks   => 'Act::Handler::User::UpdateMyTalks',
    updatemytalks_a => 'Act::Handler::User::UpdateMyTalks::ajax_handler',
    unregister      => 'Act::Handler::User::Unregister',
    wikiedit        => 'Act::Handler::WikiEdit',
);
my %dispatch = ( map( { $_ => { handler => $public_handlers{$_} } } keys %public_handlers),
                 map( { $_ => { handler => $private_handlers{$_}, private => 1 } } keys %private_handlers)
               );

# translation handler
sub trans_handler
{
    # the Apache request object
    my $r = Apache::Request->instance(shift);

    # break it up in components
    my @c = grep $_, split '/', decode_utf8($r->uri);

    # initialize our per-request variables
    %Request = (
        r         => $r,
        path_info => join('/', @c),
        base_url  => _base_url($r),
    );

    # reload configuration if needed
    Act::Config::reload_configs();

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

    # default pages a la mod_dir
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
    $Request{args} = { map { scalar $_ => decode_utf8($r->param($_)) } $r->param };
    _set_language();
    Act::Config::finalize_config($Config, $Request{language});

    # redirect language change requests
    if (delete $Request{args}{language} && !Act::Util::ua_isa_bot()) {
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
    my $pkg = $dispatch{$Request{action}}{handler};
    my @c = split '::', $pkg;
    my $handler = 'handler';
    if ($c[-1] =~ /handler$/) {
        $handler = pop @c;
    }
    $pkg = join '::', @c;
    eval "require $pkg;";
    die "require $pkg failed!" if $@;

    $pkg->$handler();
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

    # fetch localization handle
    $Request{loc} = Act::I18N->get_handle($Request{language});

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
