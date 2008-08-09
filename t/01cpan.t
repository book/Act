#!perl -w

use strict;
my %modules = (
    'Apache'                                => 0,
    'Apache::AuthCookie'                    => 3.05,
    'Apache::Request'                       => 0,
    'AppConfig'                             => 0,
    'Clone'                                 => 0,
    'Data::ICal'                            => 0,
    'Data::ICal::DateTime'                  => 0,
    'DateTime'                              => 0,
    'DateTime::Format::Pg'                  => 0,
    'DateTime::TimeZone'                    => 0,
    'DBD::Pg'                               => 1.22,
    'DBI'                                   => 0,
    'Digest::MD5'                           => 0,
    'Email::Address'                        => 0,
    'Email::Date'                           => 0,
    'Email::MessageID'                      => 0,
    'Email::Send'                           => 0,
    'Email::Send::Sendmail'                 => 0,
    'Email::Simple'                         => 0,
    'Email::Simple::Creator'                => 1.422,
    'Email::Valid'                          => 0,
    'Flickr::API'                           => 0,
    'HTML::Entities'                        => 0,
    'HTML::TagCloud'                        => 0,
    'Imager'                                => 0,
    'List::Pairwise'                        => 0,
    'Locale::Maketext'                      => 0,
    'Locale::Maketext::Lexicon'             => 0,
    'Net::OpenID::Server'                   => 0,
    'Template'                              => 2.16,
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
plan tests => 1 + 2 * keys %modules;
cmp_ok($], 'ge', 5.008001, 'perl >= 5.8.1');
while ( my ( $name, $minversion ) = each %modules ) {
    if ( require_ok($name) ) {
        my $version = eval '$' . $name . '::VERSION';
        cmp_ok( $version, '>=', $minversion,
            "$name $version >= $minversion" );
    }
    else {
        ok( 0, "$name not installed, version check failed" );
    }
}
__END__
