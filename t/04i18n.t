#!perl -w

use strict;
use Act::Config;

use Test::More tests => 3;

require_ok('Act::I18N');

$Request{language} = 'en';
my $lh = Act::I18N->get_handle($Request{language});
ok($lh, "get_handler");

my $lexicon = $lh->lexicon;
isa_ok($lexicon, "HASH", "lexicon");

__END__
