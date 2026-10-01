# ABSTRACT: Helper for Dispatcher tests
package Test::Act::Dispatcher;

use parent 'Exporter';
our @EXPORT = qw(mock_config     mock_file
                 mock_middleware mock_handler
            );

use Test::MockModule;
use Test::MockObject;
use Plack::Session::Store;
use Plack::Test;
use YAML::Tiny;


# Act::Middleware::*
sub mock_middleware {
    my $options = shift;
    return sub {
        my $self  = shift;
        my ($env) = @_;
        $env->{"act.test"}{middleware} //= [];
        push @{$env->{"act.test"}{middleware}},
            [ref $self => { map {$_ => $self->$_} @$options}];
        return $self->app->($env);
    };
}

# Act::Handler::*
sub mock_handler {
    return sub {
        my $self  = shift;
        my ($env) = @_;
        my $report = _report($self,$env);
        return _format_for_psgi($report);
    };
}

# Plack::App::File has an extra field 'root' to report
sub mock_file {
    return sub {
        my $self  = shift;
        my ($env) = @_;
        my $report = _report($self,$env,
                             root => $self->root);
        return _format_for_psgi($report);
    };
}

sub _report {
    my $self = shift;
    my $env  = shift;
    my $report = {
        app        => ref $self,
        path_info  => $env->{PATH_INFO},
        base_url   => $env->{'act.base_url'},
        middleware => $env->{"act.test"}{middleware} // [],
        @_,
    };
}

sub _format_for_psgi {
    my ($report) = @_;
    return [200, # ignored
            [],  # ignored
            [YAML::Tiny->new($report)->write_string],
           ];
}

my %uris = (
    foo => 'foo',
    bar => 'bar',
    baz => 'foo',
);

use Act::Config;
my $cfg = Test::MockObject->new;
$cfg->set_always(uris => \%uris)
    ->set_always(home => 'testhome')
    ->set_always(general_root => 'testhome')
    ->set_always(database_debug => 0)
    ->set_always(conferences => { map { $_ => 1 } values %uris })
    ->set_always(general_dir_photos => 'photos')
    ->set_always(database_dsn => $Config->database_test_dsn)
    ->set_always(database_user => $Config->database_test_user)
    ->set_always(database_passwd => $Config->database_test_passwd)
    ->set_always(database_host => $Config->database_test_host)
    ->set_always(general_dir_static => 'test_static')
    ->set_always(general_dir_conferences => 'test_dir_conferences')
    ->set_always(email_hostname => 'localhost')
    ->set_always(email_port => '25')
    ;


sub mock_config {
    return $cfg;
}

# This could be done with Test::MockModule as well,
# but as long as we don't need anything from them
# we can just overwrite them globally
{
    no warnings 'redefine';
    *Act::Config::get_config        = sub { $cfg };
    *Act::Config::finalize_config   = sub {};
    *Act::Util::db_connect          = sub {};
}

$Config = mock_config;

require Act::Dispatcher;

# Prevent the app constructor from accessing the database
my $act_session = Test::MockModule->new('Act::Session::Store');
$act_session->mock(new => sub { Plack::Session::Store->new() });

my $app    = Act::Dispatcher->to_app;
my $tester = Plack::Test->create($app);

sub driver {
    my $class = shift;
    bless {},$class;
}

sub request {
    my $self = shift;
    my ($request) = @_;
    my $response = $tester->request($request);
    my $yaml = YAML::Tiny->read_string($response->content);
    return %{$yaml->[0]};
}

__END__

=head1 NAME

Test::Act::Dispatcher - Unit tests for Act::Dispatcher

=head1 SYNOPSIS

   use HTTP::Request::Common;
   use Test::MockModule;
   use Test::Lib;
   use Test::Act::Dispatcher;

   my $fake_handler = Test::MockModule->new('Handler::Module');
   $fake_module->mock(call => fake_call);

   my $driver = Test::Act::Dispatcher->driver;
   my $Config = mock_config;

   # Test case
   my $path = '/whatever';
   my %report  = $driver->request(GET $path);
   # Examine %report

=head1 How this works

Ok, testing stuff where routines return subs which in turn return subs
is a bit scary.  So here is how it is done.

This is a pure unit test for the dispatcher.  It doesn't care for
status codes, nor for validation, nor for errors within the handlers.
All it checks is that the intended policy for the dispatcher is kept
by its code.

It does this by (ab)using Plack mechanics for its purposes:

=head2 Mocking Plack

=over

=item Applications: Act::Handler::*, Plack::App::File

A Plack application receives a hash reference C<$env> and returns a
response.  For I<all> Plack applications which are targets for the
dispatcher this module has mockups which follow this protocol.  But
instead of delivering HTML pages or images, they provide diagnostic
info: Their own class, the URL from the request as they see it, and
the list of middleware components which have been activated for the
request.  PSGI responses are just scalars, so the mock applications
serialize the information (into a YAML string, but you don't see it).

=item Middleware: Act::Middleware::*

The middleware mockups push diagnostic info into C<$env>, and then
call the mocked applications.

=back

=head2 The driver "object"

For convenience, this module provides sort of an object so that tests
can be written using OO notation:

   my %report = $driver->request(GET $path);

The driver forwards the request to the application defined by
L<Act::Dispatcher>.  C<GET> is syntactical sugar provided by
L<HTTP::Request::Common>.  It receives the response which is a
serialized hash, and converts it back to the hash for easy access by
the test cases.

Additional headers for the HTTP request can also be provided (also
courtesy of L<HTTP::Request::Common>), as in this example:

   my %report = $driver->request(GET $path, "User-Agent" => "MyRobot/5.0");

=head2 Exported functions

The module exports:

=over

=item C<mock_file> - a substution for a call to L<Plack::App::File>

=item C<mock_handler> - a substutition for C<Act::Handler::*> handlers

=item C<mock_middleware> - a substitution for C<Act::Middleware::*> modules

=item C<mock_config> - returns a mocked global C<$Config>

=back

See below for the values provided by these routines.

=head2 Act::Handler::* fields

The mock handler provides the following keys for examination:

=over

=item C<app> - its own class, e.g. C<Act::Handler::Static>

=item C<path_info> - the path seen by this application

=item C<middleware> - a list reference of middleware components for this path

=item C<base_url> - This request's base URL from the C<base> method of
L<Plack::Request>

=back

=head2 Plack::App::File fields

The mock handler for the builtin app L<Plack::App:File> provides one
additional key:

=over

=item C<root> - the root directory for this file app

=back

=head2 Act::Middleware::* fields

The middleware pushes its information into C<$env>, from where the
applications collect it into an array reference.  A mocked middleware
component reports a hash reference.

=over

=item The key is the class of the moddleware components

=item The value is a hash reference of options with which the middleware was invoked

In Act, this is used to distinguish between public and private
handlers which are both wrapped in L<Act::Middleware::Auth>.

=back

=cut

=head2 C<$Config> = mock_comfig

The configuration is mocked as an object, with a set of predefined
values.

=head2 TODO

The biggest deficit in the current tests, which it shares with the
tests of the legacy dispatcher, is the fixed set of configuration
data.  What is actually needed is testing the application under a
variety of configurations, with absolute and relative path names,
overlapping or conflicting definitions, and more.

Technically this would be done by setting up a fresh dispatcher for
every test case, with its own config mockup.  Writing this by hand is
tedious, a better solution would be to use a test environment which
support test fixtures.  L<Test::Unit> or L<Test::Routine> come into
mind, where the first has a rather unconventional (javaistic) setup
and the latter comes with a hell of dependencies.

=head2 AUTHOR

Harald Joerg, <haj@posteo.de>
