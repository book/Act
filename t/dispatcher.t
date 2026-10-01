#!perl -w

use strict;

# Modules we need
use File::Spec::Functions qw(rel2abs);
use HTTP::Request::Common;
use Act::Util;

## Test environment
use Test::More 0.98; # We're using subtests
use Test::MockModule;
use Plack::Test;
use Test::Lib;
use Test::Act::Dispatcher;

# See the description in L<Test::Act::Dispatcher> how these tests
# work. The $driver is sort of an object which accepts HTTP requests
# and turns the HTTP responses into a %results hash.
#
# The tests are organized into four groups:
#  - Tests for URLs without a conference part
#  - Tests for conference HTML pages
#  - Tests for conference actions
#  - Tests for conference files.

# main dispatch tables - copied from Act::Dispatcher.
# Test as many as you want.
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
    proceedings     => 'Act::Handler::Talk::Proceedings',
    slides          => 'Act::Handler::Talk::Slides',
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

my $plack_app_file = Test::MockModule->new('Plack::App::File');
$plack_app_file->mock(call => mock_file );

my $act_handler_static = Test::MockModule->new('Act::Handler::Static');
$act_handler_static->mock(call => mock_handler);

my $act_handler = Test::MockModule->new('Act::Handler');
$act_handler->mock(call => mock_handler);

my $act_middleware_e404 = Test::MockModule->new('Act::Middleware::ErrorPage');
$act_middleware_e404->mock(call => mock_middleware([]));

my $act_middleware_lang = Test::MockModule->new('Act::Middleware::Language');
$act_middleware_lang->mock(call => mock_middleware([]));

my $act_middleware_auth = Test::MockModule->new('Act::Middleware::Auth');
$act_middleware_auth->mock(call => mock_middleware(['private']));

# ========================================================================
# Tests start here

require_ok('Act::Dispatcher');
my $driver = Test::Act::Dispatcher->driver;
my $Config = mock_config;

subtest "Paths without a conference path" => sub {
    plan tests => 5;
  TODO: {
        # The root page of an Act conference server should deliver
        # a decent page.
        # Note: This is different from the test in the master branch
        # where the root path was expected to deliver a 404 status.
        local $TODO = "Act servers should deliver a decent root page";
        my $path = '/';
        my %report  = $driver->request(GET $path);
        like ($report{app},qr/^Act::/,
              "'$path': Act homepage is provided by an Act handler");
    }

    {
        # The root directory also holds the user photos, located
        # at a configurable directory.  Can be configured as an
        # absolute path, or relative to $ACT_HOME.
        my $path = '/photos/camel.jpg';
        my $photo_dir = $Config->general_dir_photos;
        my %report  = $driver->request(GET $path);
        is ($report{app},'Plack::App::File',
            "'$path': Processed by a file app");
        is ($report{root}, rel2abs($photo_dir,$Config->general_root),
            "'$path': Delivered from '$photo_dir'");
    }

    {
        # The root directory may also contain static documents which
        # are provided with Act software.  Every URL which does not
        # fall in a conference domain is expected to be handled by a
        # static file application.
        my $path = '/images/act_logo.png';
        my %report  = $driver->request(GET $path);
        is ($report{app},'Plack::App::File',
             "'$path': Root directory may contain non-conference files");
        is ($report{root}, $Config->general_dir_static,
            "'$path': Delivered from the correct directory");
    }
};


subtest "Conference pages" => sub {
    plan tests => 11;
    {
        # Root page for a conference should be re-routed to static
        # processing of index.html.  Language processing and
        # authentication for public consumption are required.  Note: This
        # is different from the test in the master branch where the a
        # conference root path without a trailing slash was expected to
        # deliver a 404 status.
        my $path = '/foo';
        my %report = $driver->request(GET $path);
        is ($report{app},'Act::Handler::Static',
            "'$path': Conference homepage is static");
        is ($report{path_info},'/index.html',
            "'$path': ...Rerouted to index.html");
        my $middleware = $report{middleware};
        is ($middleware->[0][0],'Act::Middleware::ErrorPage',
            "'$path': ...checked for 404");
        is ($middleware->[1][0],'Act::Middleware::Language',
            "'$path': ...is language processed");
        is ($middleware->[2][0],'Act::Middleware::Auth',
            "'$path': ....Conference homepage is subject to authentication");
        ok (! $middleware->[2][1]{private},
            "'$path': ...-but open to the public");
    }

    {
        # Same as before, but with trailing slash.  Some tests omitted.
        my $path = '/foo/';
        my %report = $driver->request(GET $path);
        is ($report{app},'Act::Handler::Static',
            "'$path': Conference homepage is static");
        is ($report{path_info},'/index.html',
            "'$path': ...Rerouted to index.html");
    }

    {
        # A typical HTML page for a conference
        my $path = '/foo/venue.html';
        my %report = $driver->request(GET $path);
        is ($report{app},'Act::Handler::Static',
            "'$path': Conference HTML pages are static");
        is ($report{path_info},'/venue.html',
            "'$path': ...correctly routed to the conference app");
    }

    {
        # URL rewriting in case of frontend web server
        # Verify https://github.com/act-psgi/ACT-PSGI-demo/issues/9
        my $path = '/foo/venue.html';
        my %report = $driver->request(GET $path,
                                      'X-Forwarded-For'  => '127.0.0.1',
                                      'X-Forwarded-Host' => 'proxied',
                                      'X-Forwarded-Proto' => 'https',
                                  );
        is($report{base_url},'https://proxied',
           "Reverse proxy handling is active");
    }
};


subtest "Conference actions" => sub {
    plan tests => 10;
    {
        # A public action: news
        my $action = 'news';
        my $path = "/foo/$action";
        my %report = $driver->request(GET $path);
        is ($report{app}, $public_handlers{$action},
            "'$path': Correct conference handler picked");
        my $middleware = $report{middleware};
        is ($middleware->[0][0],'Act::Middleware::ErrorPage',
            "'$path': ...checked for 404");
        is ($middleware->[1][0],'Act::Middleware::Language',
            "'$path': Conference action is language processed");
        is ($middleware->[2][0],'Act::Middleware::Auth',
            "'$path': Conference homepage is subject to authentication");
        ok (! $middleware->[2][1]{private},
            "'$path': ...but open to the public");
    }
    {
        # A private action: logout
        my $action = 'logout';
        my $path = "/foo/$action";
        my %report = $driver->request(GET $path);
        is ($report{app}, $private_handlers{$action},
            "'$path': Correct conference handler picked");
        my $middleware = $report{middleware};
        is ($middleware->[0][0],'Act::Middleware::ErrorPage',
            "'$path': ...checked for 404");
        is ($middleware->[1][0],'Act::Middleware::Language',
            "'$path': Conference action is language processed");
        is ($middleware->[2][0],'Act::Middleware::Auth',
            "'$path': Conference homepage is subject to authentication");
        ok ($middleware->[2][1]{private},
            "'$path': ...and restricted to authenticated users");
    }
};


subtest "Conference files" => sub {
    plan tests => 2;
    {
        # An image for a existing conference
        my $path = "/foo/images/logo.png";
        my %report = $driver->request(GET $path);
        is ($report{app}, 'Plack::App::File',
            "'$path': File to process unchanged");
        is ($report{root}, $Config->general_dir_conferences . "/foo/wwwdocs",
            "'$path': Delivered from the correct directory");
    }
};

done_testing;
