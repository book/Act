#!perl -w

use strict;
use Test::MockObject;
use Test::More tests => 11;
use Act::Config;

BEGIN { use_ok('Act::Util') }

# create a fake request object
my $uri;
$Request{r} = Test::MockObject->new;
$Request{r}->mock( uri => sub { return $uri } );

# make_uri
my @t = (
  undef,  '',     {},           '/',
  undef,  '',     { id => 42 }, '/?id=42',
  undef,  'foo',  {},           '/foo',
  '2004', 'foo',  { id => 42 }, '/2004/foo?id=42',
  '2004', 'x/y',  { id => 42 }, '/2004/x/y?id=42',
  '2004', 'foo',  { q => 'x', r => ' y' }, '/2004/foo?q=x&r=%20y',
);
while (my ($conf, $action, $args, $expected) = splice(@t, 0, 4)) {
    $Request{conference} = $conf;
    is(make_uri($action, %$args), $expected);
}

# self_uri
@t = (
 '/foo', {}, '/foo',
 '/foo', { q => 42 }, '/foo?q=42',
 '/foo', { q => 'x y' }, '/foo?q=x%20y',
 '/foo', { q => 'x', r => 'y' }, '/foo?q=x&r=y',
);
while (my ($u, $args, $expected) = splice(@t, 0, 3)) {
    $uri = $u;
    is(self_uri(%$args), $expected);
}

__END__
