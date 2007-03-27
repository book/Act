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
                 'Locale::Maketext',
                 'Locale::Maketext::Lexicon',
                 'Template',
                 'Template::Multilingual::Parser',
                 'Test::MockObject',
                 'Text::Diff',
                 'Text::WikiFormat',
                 'Text::xSV',
                 'URI',
                 'URI::Escape',
                 'Wiki::Toolkit',
              );
use Test::More;
plan tests => 1 + scalar(@modules);
cmp_ok($], 'ge', 5.008001, 'perl >= 5.8.1');
for my $m (@modules) {
    require_ok($m);
}
__END__
