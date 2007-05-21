#!perl -w

use strict;
my @modules = (
    'Apache'                                => 0,
    'Apache::AuthCookie'                    => 3.05,
    'Apache::Request'                       => 0,
    'AppConfig'                             => 0,
    'DateTime'                              => 0,
    'DateTime::Format::ICal'                => 0,
    'DateTime::Format::Pg'                  => 0,
    'DateTime::TimeZone'                    => 0,
    'DBD::Pg'                               => 1.22,
    'DBI'                                   => 0,
    'Digest::MD5'                           => 0,
    'Email::Valid'                          => 0,
    'Imager'                                => 0,
    'HTML::Entities'                        => 0,
    'Locale::Maketext'                      => 0,
    'Locale::Maketext::Lexicon'             => 0,
    'Template'                              => 2.15,
    'Template::Multilingual::Parser'        => 0,
    'Test::MockObject'                      => 0,
    'Text::Diff'                            => 0,
    'Text::WikiFormat'                      => 0,
    'Text::xSV'                             => 0,
    'URI'                                   => 1.31,
    'Wiki::Toolkit'                         => 0,
    'XML::Atom'                             => 0.20,
);
use Test::More;
plan tests => 1 + @modules;
cmp_ok($], 'ge', 5.008001, 'perl >= 5.8.1');
while (my ($name, $minversion) = splice(@modules,0,2)) {
    require_ok($name);
    my $version = eval '$' . $name . '::VERSION';
    cmp_ok($version, '>=', $minversion, "$name $version >= $minversion");
}
__END__
