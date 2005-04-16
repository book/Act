# préchargements pour mod_perl

$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/ or die "GATEWAY_INTERFACE not Perl!";

# mod_perl modules
use Apache::Constants  qw(:common);

# CPAN modules
use Apache::AuthCookie ();
use Apache::Cookie     ();
use AppConfig          ();
use DBI                ();
use Digest::MD5        ();
use Email::Valid       ();
use HTML::Entities     ();
use MIME::Lite         ();
use Net::SMTP          ();
use Storable           ();
use Template           ();
use URI::Escape        ();

# Act modules
use Act::Auth;
use Act::Config;
use Act::Dispatcher;
use Act::Email;
use Act::Form;
use Act::Handler::Payment::Confirm;
use Act::Talk;
use Act::Template;
use Act::User;
use Act::Util;

use Act::Handler::Static;

# preload DBD drivers
DBI->install_driver('Pg');

1;
