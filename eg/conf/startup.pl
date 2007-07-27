# préchargements pour mod_perl

$ENV{GATEWAY_INTERFACE} =~ /^CGI-Perl/ or die "GATEWAY_INTERFACE not Perl!";

# Act handlers
use Act::Auth;
use Act::Dispatcher;
use Act::Handler::Event::Edit;
use Act::Handler::Event::Show;
use Act::Handler::Login;
use Act::Handler::Logout;
use Act::Handler::News::Admin;
use Act::Handler::News::Atom;
use Act::Handler::News::Edit;
use Act::Handler::News::Fetch;
use Act::Handler::Payment::Confirm;
use Act::Handler::Payment::Invoice;
use Act::Handler::Payment::List;
use Act::Handler::Payment::Payment;
use Act::Handler::Static;
use Act::Handler::Talk::Edit;
use Act::Handler::Talk::ExportCSV;
use Act::Handler::Talk::ExportIcal;
use Act::Handler::Talk::Import;
use Act::Handler::Talk::List;
use Act::Handler::Talk::Schedule;
use Act::Handler::Talk::Show;
use Act::Handler::Track::Edit;
use Act::Handler::Track::List;
use Act::Handler::User::Change;
use Act::Handler::User::ChangePassword;
use Act::Handler::User::Main;
use Act::Handler::User::Photo;
use Act::Handler::User::Purchase;
use Act::Handler::User::Register;
use Act::Handler::User::Rights;
use Act::Handler::User::Search;
use Act::Handler::User::Show;
use Act::Handler::User::Stats;
use Act::Handler::User::Unregister;
use Act::Handler::Wiki;

# preload DBD drivers
DBI->install_driver('Pg');

1;
