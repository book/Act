#!perl -w

use strict;
use utf8;
use DateTime;
use Test::MockObject;
use constant NBPASS => 100;
use Test::More tests => 72 + 5 * NBPASS;
use Act::Config;

BEGIN { use_ok('Act::Util') }

# create a fake request object
my $uri;
$Request{r} = Test::MockObject->new;
$Request{r}->mock(uri => sub { return $uri } );

# create a fake config object
$Config = Test::MockObject->new;
$Config->mock( uri => sub { return $Request{conference} } );

# make_uri
my @t = (
  undef,  '',     {},           '/',
  undef,  '',     { id => 42 }, '/?id=42',
  undef,  'foo',  {},           '/foo',
  '2004', 'foo',  { id => 42 }, '/2004/foo?id=42',
  '2004', 'x/y',  { id => 42 }, '/2004/x/y?id=42',
  '2004', 'foo',  { id => 'césâr' }, '/2004/foo?id=c%C3%A9s%C3%A2r',
  '2004', 'foo',  { q => 'x', r => ' y' }, '/2004/foo?q=x&r=%20y',
);
while (my ($conf, $action, $args, $expected) = splice(@t, 0, 4)) {
    $Request{conference} = $conf;
    is(make_uri($action, %$args), $expected);
}

# make_uri_info
@t = (
  undef,  'foo', undef,     '/foo',
  undef,  'foo', 'bar',     '/foo/bar',
  '2004', 'foo', 'bar',     '/2004/foo/bar',
  '2004', 'foo', 'bar/baz', '/2004/foo/bar/baz',
);
while (my ($conf, $action, $pathinfo, $expected) = splice(@t, 0, 4)) {
    $Request{conference} = $conf;
    is(make_uri_info($action, $pathinfo), $expected);
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

# gen_password
my %seen;
for (1..NBPASS) {
    my ($clear, $crypted) = Act::Util::gen_password();
    ok($clear);
    ok(!$seen{$clear}++);
    ok($crypted);
    like($clear,   qr/^[a-z]+$/);
    like($crypted, qr/^\S+$/);
}
# date_format
use utf8;
$Request{language} = 'fr';
my $dt = DateTime->new(year => 2007, month => 2, day => 15);
is(Act::Util::date_format($dt, 'datetime_full'), 'jeudi 15 février 2007 00h00', 'date_format');

# normalize
use charnames ();

@t = (  a => [ qw(à á â ã ä å À Á Â Ã Ä Å) ],
        c => [ qw(ç Ç) ],
        e => [ qw(è é ê ë È É Ê Ë) ],
        i => [ qw(ì í î ï Ì Í Î Ï) ],
        n => [ qw(ñ Ñ) ],
        o => [ qw(ò ó ô õ ö Ò Ó Ô Õ Ö) ],
        u => [ qw(ù ú û ü Ù Ú Û Ü) ],
        y => [ qw(ý ÿ Ý Ÿ) ],
     );
while (my ($n, $dlist) = splice(@t, 0, 2)) {
    for my $chr (@$dlist) {
        is (Act::Util::normalize($chr), $n, charnames::viacode(ord($chr)));
    }
}

# usort
my @sorted = Act::Util::usort { $_ } qw(éb ec eà);
is_deeply(\@sorted, [qw(eà éb ec)], 'usort');

__END__
