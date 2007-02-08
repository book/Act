#!perl -w

use strict;
my @modules = (
                 'Apache',
                 'Apache::AuthCookie',
                 'Apache::Cookie',
                 'Apache::Request',
                 'AppConfig',
                 'DateTime',
                 'DateTime::Format::ICal',
                 'DateTime::Format::Pg',
                 'DateTime::TimeZone',
                 'DBD::Pg',
                 'DBI',
                 'Digest::MD5',
                 'Email::Valid',
                 'HTML::Entities',
                 'MIME::Lite',
                 'Net::SMTP',
                 'Template',
                 'Template::Multilingual::Parser',
                 'Text::Diff',
                 'Test::MockObject',
                 'Text::Iconv',
                 'Text::xSV',
                 'URI',
                 'URI::Escape',
                 'Wiki::Toolkit',
              );
use Test::More;
plan tests => 1 + scalar(@modules);
cmp_ok($], 'ge', 5.006001, 'perl >= 5.6.1');
for my $m (@modules) {
    require_ok($m);
}
__END__
