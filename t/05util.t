#!perl -w

use strict;
use utf8;
use DateTime;
use Test::MockObject;
use constant NBPASS => 100;
use Test::More tests => 79 + 5 * NBPASS;
use Act::Config;

BEGIN { use_ok('Act::Util') }

# create a fake request object
my $uri;
my %headers;
$Request{r} = Test::MockObject->new;
$Request{r}->mock( uri       => sub { return $uri } );
$Request{r}->mock( header_in => sub { return $headers{ $_[1] } } );

# create a fake config object
my %variants;
$Config = Test::MockObject->new;
$Config->mock( uri => sub { return $Request{conference} } );
$Config->mock( language_variants => sub { return \%variants } );

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
my $dt = DateTime->new(year => 2007, month => 2, day => 15, hour => 13);
is(Act::Util::date_format($dt, 'datetime_full'), 'jeudi 15 février 2007 13h00', 'date_format fr');

$Request{language} = 'ru';  # test genitive month name
is(Act::Util::date_format($dt, 'datetime_full'), 'четверг, 15 февраля 2007 г., 13:00', 'date_format ru');

$Request{language} = 'en';
$variants{en} = 'en_GB';
is(Act::Util::date_format($dt, 'datetime_full'), 'Thursday, 15 February 2007 13:00', 'date_format en_GB');
$variants{en} = 'en_US';
is(Act::Util::date_format($dt, 'datetime_full'), 'Thursday, February 15, 2007 01:00 PM', 'date_format en_US');

$variants{en} = 'en_NZ';   # not in %Languages, fallback to 'en'
is(Act::Util::date_format($dt, 'datetime_full'), 'Thursday, 15 February 2007 13:00', 'date_format en_NZ (aka en aka en_GB)');

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
# normalize exceptions
is (Act::Util::normalize('йéйè'), 'йeйe', charnames::viacode(ord('й')));

# usort
my @sorted = Act::Util::usort { $_->{foo} } ( { foo => 'éb' }, { foo => 'ec' }, { foo => 'eà' } );
is_deeply(\@sorted, [ { foo => 'eà' }, { foo => 'éb' }, { foo => 'ec' } ], 'usort');

# ua_isa_bot
$headers{'User-Agent'} = 'Mozilla/4.76 [en] (X11; U; FreeBSD 4.4-STABLE i386)';
ok( !Act::Util::ua_isa_bot(), 'Mozilla != bot' );

$headers{'User-Agent'} = 'Mozilla/5.0 (compatible; Googlebot/2.1; http://www.google.com/bot.html)';
ok( Act::Util::ua_isa_bot(), 'GoogleBot == bot' );

__END__
