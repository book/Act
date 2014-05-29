use inc::Module::Install;
all_from 'lib/Act.pm';

requires(
'Apache::AuthCookie' => 3.05, 
'Apache::Constants' => 0, 
'Apache::Cookie' => 0, 
'Apache::Request' => 0, 
'AppConfig' => 0, 
'Clone' => 0, 
'DBI' => 0, 
'DBD::Pg' => 1.22,
'Data::ICal' => '0.16', # Data::ICal::Entry::Event
'Data::ICal::DateTime' => 0,
'Data::ICal::TimeZone' => 0,
'DateTime::Format::Pg' => 0, 
'DateTime::Locale' => 0, 
'DateTime::TimeZone' => 0, 
'DateTime' => 0, 
'Digest::HMAC_SHA1' => 0, 
'Email::Address' => 0, 
'Email::Date' => 0, 
'Email::MessageID' => 1.4,
'Email::Send' => 0, 
'Email::Send::Sendmail' => 0, 
'Email::Simple::Creator' => 0, 
'Email::Simple' => 0, 
'Email::Valid' => 0, 
'Flickr::API' => 0, 
'HTML::Entities' => 0, 
'HTML::TagCloud' => 0, 
'HTTP::Request::Common' => 0, 
'Imager' => 0, 
'JSON::XS' => 0, 
'LWP::Simple' => 0, 
'LWP::UserAgent' => 0, 
'List::Pairwise' => 0, 
'Locale::Maketext::Lexicon' => 0, 
'Net::OpenID::Server' => 0, 
'Pod::POM' => 0, 
'Template' => 2.16, # Template::Constants
'Template::Multilingual::Parser' => 0, 
'Term::ReadKey' => 0, 
'Test::MockObject' => 0, 
'Text::Diff' => 0, 
'Text::WikiFormat' => 0, 
'Text::xSV' => 0, 
'URI::Escape' => 0, 
'URI' => 1.31, 
'Wiki::Toolkit' => 0, # Wiki::Toolkit::Formatter::Default Wiki::Toolkit::Store::Pg
'XML::Atom' => '0.20',   # XML::Atom::Entry XML::Atom::Feed XML::Atom::Link
'version' => 0,
);
auto_install();
&WriteAll;
