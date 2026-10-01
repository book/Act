use strict;
use warnings;

use 5.020;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A conference toolkit",
  "AUTHOR" => "Harald J\x{f6}rg <haj\@posteo.de>",
  "CONFIGURE_REQUIRES" => {
    "CPAN::Meta::Requirements" => "2.120620",
    "ExtUtils::MakeMaker" => 0,
    "Module::Metadata" => 0
  },
  "DISTNAME" => "Act",
  "EXE_FILES" => [
    "bin/dbbackup",
    "bin/dbinit",
    "bin/dbupdate",
    "bin/findtwins",
    "bin/gengrant",
    "bin/genpasswd",
    "bin/gitupdate",
    "bin/grant_rights",
    "bin/list_payments",
    "bin/makedoc",
    "bin/mergeusers",
    "bin/metacpan_conf_info",
    "bin/mk_y2a_conf",
    "bin/monk_names",
    "bin/normalize_photos",
    "bin/paymentreport",
    "bin/pm_groups",
    "bin/split_orga_rights",
    "bin/svnupdate",
    "bin/translator",
    "bin/tt2utf8",
    "bin/ttextract",
    "bin/twostep_purge"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.020",
  "NAME" => "Act",
  "PREREQ_PM" => {
    "AppConfig" => 0,
    "Authen::Passphrase" => 0,
    "Authen::Passphrase::BlowfishCrypt" => 0,
    "Carp" => 0,
    "Clone" => 0,
    "DBD::Pg" => 3,
    "DBI" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "DBIx::Connector" => 0,
    "Data::Dumper" => 0,
    "Data::ICal" => "0.16",
    "Data::ICal::DateTime" => 0,
    "Data::ICal::Entry::Event" => 0,
    "Data::ICal::TimeZone" => 0,
    "Date::Parse" => 0,
    "DateTime::Format::HTTP" => 0,
    "DateTime::TimeZone" => 0,
    "Digest::HMAC_SHA1" => 0,
    "Digest::MD5" => 0,
    "Digest::SHA" => 0,
    "Email::Address" => 0,
    "Email::Date" => 0,
    "Email::MessageID" => "1.4",
    "Email::Send" => 0,
    "Email::Simple" => 0,
    "Email::Simple::Creator" => 0,
    "Email::Valid" => 0,
    "Encode" => 0,
    "Expect" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Flickr::API" => 0,
    "Getopt::Long" => 0,
    "Getopt::Std" => 0,
    "HTML::Entities" => 0,
    "HTML::TagCloud" => 0,
    "HTTP::Request::Common" => 0,
    "IPC::Open2" => 0,
    "Imager" => 0,
    "JSON" => 0,
    "JSON::XS" => 0,
    "LWP::Simple" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "Locale::Maketext" => 0,
    "Locale::Maketext::Lexicon" => 0,
    "Module::Pluggable::Object" => 0,
    "Moo" => 0,
    "MooX::Singleton" => 0,
    "Net::OpenID::Server" => 0,
    "Plack::App::File" => 0,
    "Plack::Builder" => 0,
    "Plack::Component" => 0,
    "Plack::Middleware" => 0,
    "Plack::Middleware::Debug" => 0,
    "Plack::Middleware::ReverseProxy" => 0,
    "Plack::Request" => 0,
    "Plack::Response" => 0,
    "Plack::Session" => 0,
    "Plack::Session::State::Cookie" => 0,
    "Plack::Session::Store::DBI" => 0,
    "Plack::Util" => 0,
    "Plack::Util::Accessor" => 0,
    "Pod::POM" => 0,
    "Pod::POM::View::HTML" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "Template" => "2.16",
    "Template::Constants" => 0,
    "Template::Multilingual::Parser" => 0,
    "Term::ANSIColor" => 0,
    "Term::ReadKey" => 0,
    "Text::Diff" => 0,
    "Text::TabularDisplay" => 0,
    "Text::WikiFormat" => 0,
    "Text::xSV" => 0,
    "Tie::IxHash" => 0,
    "Time::Piece" => 0,
    "Time::Seconds" => 0,
    "Try::Tiny" => 0,
    "Types::Standard" => 0,
    "URI" => "1.31",
    "URI::Escape" => 0,
    "Unicode::Collate" => 0,
    "Unicode::Normalize" => 0,
    "Wiki::Toolkit" => 0,
    "Wiki::Toolkit::Formatter::Default" => 0,
    "Wiki::Toolkit::Store::Pg" => 0,
    "XML::Atom" => "0.20",
    "XML::Atom::Entry" => 0,
    "XML::Atom::Feed" => 0,
    "XML::Atom::Link" => 0,
    "XML::Simple" => 0,
    "YAML" => 0,
    "base" => 0,
    "constant" => 0,
    "feature" => 0,
    "lib" => 0,
    "lib::abs" => "0.93",
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime::Locale" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Path::Tiny" => 0,
    "Plack::Session::Store" => 0,
    "Plack::Test" => 0,
    "Test" => 0,
    "Test::Builder" => 0,
    "Test::Deep" => 0,
    "Test::Deep::NoTest" => 0,
    "Test::Exception" => 0,
    "Test::Fatal" => 0,
    "Test::Lib" => 0,
    "Test::MockModule" => 0,
    "Test::MockObject" => 0,
    "Test::More" => "0.98",
    "Test::Pod" => 0,
    "YAML::Tiny" => 0,
    "open" => 0
  },
  "VERSION" => "2.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AppConfig" => 0,
  "Authen::Passphrase" => 0,
  "Authen::Passphrase::BlowfishCrypt" => 0,
  "Carp" => 0,
  "Clone" => 0,
  "DBD::Pg" => 3,
  "DBI" => 0,
  "DBIx::Class::Core" => 0,
  "DBIx::Class::Schema" => 0,
  "DBIx::Connector" => 0,
  "Data::Dumper" => 0,
  "Data::ICal" => "0.16",
  "Data::ICal::DateTime" => 0,
  "Data::ICal::Entry::Event" => 0,
  "Data::ICal::TimeZone" => 0,
  "Date::Parse" => 0,
  "DateTime::Format::HTTP" => 0,
  "DateTime::Locale" => 0,
  "DateTime::TimeZone" => 0,
  "Digest::HMAC_SHA1" => 0,
  "Digest::MD5" => 0,
  "Digest::SHA" => 0,
  "Email::Address" => 0,
  "Email::Date" => 0,
  "Email::MessageID" => "1.4",
  "Email::Send" => 0,
  "Email::Simple" => 0,
  "Email::Simple::Creator" => 0,
  "Email::Valid" => 0,
  "Encode" => 0,
  "Expect" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Fcntl" => 0,
  "File::Basename" => 0,
  "File::Find" => 0,
  "File::Path" => 0,
  "File::Slurp" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Flickr::API" => 0,
  "Getopt::Long" => 0,
  "Getopt::Std" => 0,
  "HTML::Entities" => 0,
  "HTML::TagCloud" => 0,
  "HTTP::Request::Common" => 0,
  "IPC::Open2" => 0,
  "Imager" => 0,
  "JSON" => 0,
  "JSON::XS" => 0,
  "LWP::Simple" => 0,
  "LWP::UserAgent" => 0,
  "List::Util" => 0,
  "Locale::Maketext" => 0,
  "Locale::Maketext::Lexicon" => 0,
  "Module::Pluggable::Object" => 0,
  "Moo" => 0,
  "MooX::Singleton" => 0,
  "Net::OpenID::Server" => 0,
  "Path::Tiny" => 0,
  "Plack::App::File" => 0,
  "Plack::Builder" => 0,
  "Plack::Component" => 0,
  "Plack::Middleware" => 0,
  "Plack::Middleware::Debug" => 0,
  "Plack::Middleware::ReverseProxy" => 0,
  "Plack::Request" => 0,
  "Plack::Response" => 0,
  "Plack::Session" => 0,
  "Plack::Session::State::Cookie" => 0,
  "Plack::Session::Store" => 0,
  "Plack::Session::Store::DBI" => 0,
  "Plack::Test" => 0,
  "Plack::Util" => 0,
  "Plack::Util::Accessor" => 0,
  "Pod::POM" => 0,
  "Pod::POM::View::HTML" => 0,
  "Pod::Usage" => 0,
  "Scalar::Util" => 0,
  "Template" => "2.16",
  "Template::Constants" => 0,
  "Template::Multilingual::Parser" => 0,
  "Term::ANSIColor" => 0,
  "Term::ReadKey" => 0,
  "Test" => 0,
  "Test::Builder" => 0,
  "Test::Deep" => 0,
  "Test::Deep::NoTest" => 0,
  "Test::Exception" => 0,
  "Test::Fatal" => 0,
  "Test::Lib" => 0,
  "Test::MockModule" => 0,
  "Test::MockObject" => 0,
  "Test::More" => "0.98",
  "Test::Pod" => 0,
  "Text::Diff" => 0,
  "Text::TabularDisplay" => 0,
  "Text::WikiFormat" => 0,
  "Text::xSV" => 0,
  "Tie::IxHash" => 0,
  "Time::Piece" => 0,
  "Time::Seconds" => 0,
  "Try::Tiny" => 0,
  "Types::Standard" => 0,
  "URI" => "1.31",
  "URI::Escape" => 0,
  "Unicode::Collate" => 0,
  "Unicode::Normalize" => 0,
  "Wiki::Toolkit" => 0,
  "Wiki::Toolkit::Formatter::Default" => 0,
  "Wiki::Toolkit::Store::Pg" => 0,
  "XML::Atom" => "0.20",
  "XML::Atom::Entry" => 0,
  "XML::Atom::Feed" => 0,
  "XML::Atom::Link" => 0,
  "XML::Simple" => 0,
  "YAML" => 0,
  "YAML::Tiny" => 0,
  "base" => 0,
  "constant" => 0,
  "feature" => 0,
  "lib" => 0,
  "lib::abs" => "0.93",
  "open" => 0,
  "parent" => 0,
  "strict" => 0,
  "utf8" => 0,
  "vars" => 0,
  "warnings" => 0
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.035
requires('JSON::XS', '4.02') if has_module('JSON::XS', '4.01') or !defined has_module('JSON::XS','4.01');


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.035
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub has_module {
  my ($module, $version_or_range) = @_;
  require Module::Metadata;
  my $mmd = Module::Metadata->new_from_module($module);
  return undef if not $mmd;
  return $mmd->version($module) if not defined $version_or_range;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;
  $req->add_string_requirement($module => $version_or_range);
  return 1 if $req->accepts_module($module => $mmd->version($module));
  return 0;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(PREREQ_PM => $module, $version_or_range);
}
