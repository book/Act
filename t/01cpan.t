#!perl -w

use strict;
my @modules = (
                 'Apache',
                 'Apache::AuthCookie',
                 'Apache::Cookie',
                 'AppConfig',
                 'DBD::Pg',
                 'DBI',
                 'Digest::MD5',
                 'HTML::Entities',
                 'MIME::Lite',
                 'Net::SMTP',
                 'Template',
                 'Test::MockObject',
                 'URI::Escape',
              );
use Test::More;
plan tests => 1 + scalar(@modules);
cmp_ok($], 'ge', 5.006001, 'perl >= 5.6.1');
for my $m (@modules) {
    require_ok($m);
}
__END__
