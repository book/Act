#!perl -w

use strict;
use Test::MockObject;
use Test::More;
use Act::Config;
use Act::Util;

# Apache::Constants doesn't work offline
BEGIN {
    my %ac = (
        OK        => 0,
        DECLINED  => 403,
        REDIRECT  => 302,
    );
    {
        require Exporter;
        $INC{'Apache/Constants'} = 1;
        @Apache::Constants::ISA = 'Exporter';
        @Apache::Constants::EXPORT = keys %ac;
        while (my ($k, $v) = each %ac) {
            no strict 'refs';
            *{"Apache::Constants::$k"} = sub { $v };
        }
        Apache::Constants->import;
    }
}
my %uris = (
    foo => 'foo',
    bar => 'bar',
    baz => 'foo',
);
my %default = (
 input => {
   request_uri => '',
   args        => {},
   host        => 'localhost',
   port        => 80,
   method      => 'GET',
   headers_in  => {
       'User-Agent' => 'Mozilla',
   },
 },
 output => {
   path_info   => '',
   base_url    => 'http://localhost',
 },
);
my @tests = (
 { # input
   request_uri => '/',
   # output
   status      => DECLINED,
 },
 { # input
   request_uri => '/page',
   # output
   status      => DECLINED,
   path_info   => 'page',
 },
 { # input
   request_uri => '/foo',
   # output
   status      => DECLINED,
   conf        => 'foo',
 },
 { # input
   request_uri => '/bar',
   # output
   status      => DECLINED,
   conf        => 'bar',
 },
 { # input
   request_uri => '/baz',
   # output
   status      => DECLINED,
   conf        => 'foo',
 },
 { # input
   request_uri => '/foo/',
   # output
   status      => DECLINED,
   conf        => 'foo',
   path_info   => 'index.html',
 },
 { # input
   request_uri => '/foo/index.html',
   # output
   status      => OK,
   conf        => 'foo',
   path_info   => 'index.html',
   handler     => 'Act::Handler::Static',
 },
 { # input
   request_uri => '/foo/index.html',
   args        => { language => 'fr' },
   # output
   status      => REDIRECT,
   conf        => 'foo',
   path_info   => 'index.html',
   headers_out => { Location => '/foo/index.html' },
 },
 { # input
   request_uri => '/foo/index.html',
   args        => { language => 'fr' },
   headers_in  => { 'User-Agent' => 'googlebot' },
   # output
   status      => OK,
   conf        => 'foo',
   path_info   => 'index.html',
   handler     => 'Act::Handler::Static',
 },
 { # input
   request_uri => '/foo/login',
   host        => 'aa',
   # output
   status      => OK,
   conf        => 'foo',
   handler     => 'Act::Dispatcher',
   action      => 'login',
   base_url    => 'http://aa',
 },
 { # input
   request_uri => '/foo/logout',
   host        => 'bb',
   port        => 81,
   # output
   status      => OK,
   conf        => 'foo',
   handler     => 'Act::Dispatcher',
   action      => 'logout',
   private     => 1,
   base_url    => 'http://bb:81',
 },
);

plan tests => 1 + 8 * scalar(@tests);

# fake some context
my (%vin, %vout);

my $cfg = Test::MockObject->new;
$cfg->set_always(uris => \%uris)
    ->set_always(conferences => { map { $_ => 1 } values %uris })
    ->mock(uri => $vin{request_uri});

my $s = Test::MockObject->new;
$s->mock(server_hostname => sub { $vin{host} })
  ->mock(port => sub { $vin{port} });

my $h = Test::MockObject->new;
$h->mock(set => sub { shift; $vout{headers_out} = { @_ } });

my $r = Test::MockObject->new;
$r->set_always(server      => $s)
  ->set_always(headers_out => $h)
  ->set_true(qw(handler status send_http_header))
  ->mock(uri           => sub { $vin{request_uri} })
  ->mock(method        => sub { @_ > 1 and $vout{method} = $_[1]; $vin{method} })
  ->mock(push_handlers => sub { $vout{pushed_handler} = $_[2] })
  ->mock(header_in     => sub { $vin{headers_in}{$_[1]} })
  ->mock(param         => sub { @_ > 1 ? $vin{args}{$_[1]} : keys %{$vin{args}} });

Test::MockObject->fake_module('Apache::Request', instance => sub { $r });

use_ok('Act::Dispatcher');

{
    no warnings 'redefine';
    *Act::Config::get_config        = sub { $cfg };
    *Act::Config::finalize_config   = sub {};
    *Act::Util::db_connect          = sub {};
    *Act::Dispatcher::_set_language = sub {};
}
$Config = $cfg;

# trans handler tests
for my $t (@tests) {
    %vin = map { $_ => $t->{$_} || $default{input}{$_} } keys %{$default{input}};
    %vout = ();
    $t->{$_} ||= $default{output}{$_} for keys %{$default{output}};

    my $uri = $t->{request_uri};
    is(Act::Dispatcher::trans_handler(), $t->{status}, "$uri status");
    is($Request{conference},  $t->{conf},      "$uri conf");
    is($Request{path_info},   $t->{path_info}, "$uri path_info");
    is($Request{action},      $t->{action},    "$uri action");
    is($Request{private},     $t->{private},   "$uri private");
    is($Request{base_url},    $t->{base_url},  "$uri base_url");

    is($vout{pushed_handler}, $t->{handler},   "$uri handler");
    is_deeply($vout{headers_out}, $t->{headers_out}, "$uri headers_out");
}

__END__
