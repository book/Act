#!perl -w

use strict;
my @modules = (
                 'Apache',
                 'AppConfig',
                 'DBD::Pg',
                 'DBI',
                 'HTML::Entities',
                 'Template',
              );
use Test::More;
plan tests => 1 + scalar(@modules);
cmp_ok($], 'ge', 5.006001, 'perl >= 5.6.1');
for my $m (@modules) {
    require_ok($m);
}
__END__
