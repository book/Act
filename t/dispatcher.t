#!perl -w

use strict;
use Test::MockObject;
use Test::More;
use Act::Config;

# Apache::Constants doesn't work offline
BEGIN {
    my %ac = (
        OK        => 0,
        DECLINED  => 403,
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
my @tests = (
  # request_uri       status     path_info      conference  handler                action  private
[ '/',                DECLINED,  'index.html' ],
[ '/page',            DECLINED,  'page',      ],
[ '/foo',             DECLINED,  '',           'foo' ],
[ '/bar',             DECLINED,  '',           'bar' ],
[ '/baz',             DECLINED,  '',           'foo' ],
[ '/foo/',            DECLINED,  'index.html', 'foo' ],
[ '/foo/index.html',  OK,        'index.html', 'foo',       'Act::Handler::Static' ],
[ '/foo/login',       OK,        '',           'foo',       'Act::Dispatcher',     'login'     ],
[ '/foo/logout',      OK,        '',           'foo',       'Act::Dispatcher',     'logout', 1 ],
);

plan tests => 1 + 6 * scalar(@tests);

# fake some context
my ($request_uri, $pushed_handler);

my $cfg = Test::MockObject->new;
$cfg->set_always(uris => \%uris)
    ->mock(uri => $request_uri);

my $r = Test::MockObject->new;
$r->mock(uri => sub { $request_uri })
  ->set_always(param => {})
  ->set_true  (qw(handler))
  ->mock      (push_handlers => sub { $pushed_handler = $_[2] });

Test::MockObject->fake_module('Apache::Request', instance => sub { $r });

use_ok('Act::Dispatcher');

{
    no warnings 'redefine';
    *Act::Config::get_config = sub { $cfg };
    *Act::Dispatcher::_db_connect   = sub {};
    *Act::Dispatcher::_set_language = sub {};
}

# trans handler tests
for my $t (@tests) {
    ($request_uri, my ($status, $path_info, $conf, $handler, $action, $private)) = @$t;
    undef $pushed_handler;
    is(Act::Dispatcher::trans_handler(), $status, "$request_uri status");
    is($Request{conference}, $conf,      "$request_uri conf");
    is($Request{path_info},  $path_info, "$request_uri path_info");
    is($pushed_handler,      $handler,   "$request_uri handler");
    is($Request{action},     $action,    "$request_uri action");
    is($Request{private},    $private,   "$request_uri private");
}

__END__
