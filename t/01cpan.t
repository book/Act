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
                 'Imager',
                 'HTML::Entities',
                 'Locale::Maketext',
                 'Locale::Maketext::Lexicon',
                 'Template|2.15',
                 'Template::Multilingual::Parser',
                 'Test::MockObject',
                 'Text::Diff',
                 'Text::WikiFormat',
                 'Text::xSV',
                 'URI',
                 'URI::Escape',
                 'Wiki::Toolkit',
                 'XML::Atom',
              );
use Test::More;
plan tests => 1 + 2 * @modules;
cmp_ok($], 'ge', 5.008001, 'perl >= 5.8.1');
for my $m (@modules) {
    my ($name, $minversion) = split /\|/, $m;
    require_ok($name);
    SKIP: {
        skip "no minimum version required", 1 unless $minversion;
        my $version = eval '$' . $name . '::VERSION';
        cmp_ok($version, '>=', $minversion, "$name $version >= $minversion");
    };
}
__END__
