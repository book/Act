# préchargements pour mod_perl

$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/ or die "GATEWAY_INTERFACE not Perl!";

# mod_perl modules
use Apache::Constants  qw(:common);

# CPAN modules
use Apache::AuthCookie ();
use Apache::Cookie     ();
use Apache::Request    ();
use AppConfig          ();
use DateTime           ();
use DBI                ();
use Digest::MD5        ();
use Email::Valid       ();
use HTML::Entities     ();
use MIME::Lite         ();
use Net::SMTP          ();
use Template           ();
use URI::Escape        ();

# Act handlers
use Act::Auth;
use Act::Dispatcher;
use Act::Handler::Event::Edit;
use Act::Handler::Event::Show;
use Act::Handler::Login;
use Act::Handler::Logout;
use Act::Handler::Payment::Confirm;
use Act::Handler::Payment::Invoice;
use Act::Handler::Payment::List;
use Act::Handler::Payment::Payment;
use Act::Handler::Static;
use Act::Handler::Talk::Edit;
use Act::Handler::Talk::Export;
use Act::Handler::Talk::Import;
use Act::Handler::Talk::List;
use Act::Handler::Talk::Schedule;
use Act::Handler::Talk::Show;
use Act::Handler::User::Change;
use Act::Handler::User::Main;
use Act::Handler::User::Photo;
use Act::Handler::User::Purchase;
use Act::Handler::User::Register;
use Act::Handler::User::ResetPassword;
use Act::Handler::User::Rights;
use Act::Handler::User::Search;
use Act::Handler::User::Show;
use Act::Handler::User::Stats;
use Act::Handler::User::Unregister;
use Act::Handler::Wiki;

# preload DBD drivers
DBI->install_driver('Pg');

1;
