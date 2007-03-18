#!perl -w

use strict;
use Act::Config;

use Test::More tests => 2;

require_ok('Act::I18N');

$Request{language} = 'en';
my $lh = Act::I18N->get_handle($Request{language});
ok($lh, "get_handler");

__END__
