#!perl -w

use strict;
use Act::Config;

use Test::More tests => 5;

require_ok('Act::I18N');

$Request{language} = 'en';
$Config->set(general_default_language => 'en');

my $lh = Act::I18N->get_handle($Request{language});
ok($lh, "get_handle en");
is($lh->maketext('foo'), 'TRANSLATEME', 'unknown string, default language');

$Request{language} = 'fr';
$lh = Act::I18N->get_handle($Request{language});
ok($lh, "get_handle fr");
is($lh->maketext('foo'), 'TRANSLATEME', 'unknown string, non default language');

__END__
