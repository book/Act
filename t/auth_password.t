#!perl -w
package main; # Make Devel::PerlySense happy

## Test environment
use Test::More 0.98 tests => 20;
use Digest::MD5;
use Test::Lib;

use Act::Store::Database; # For cleanup

use utf8; # for our test passwords


## Test preparations ---------------------------------------------------
# Some test data
my %passwords = (
    ascii     => 'Only_ASCII_characters',
    iso_latin => 'Âccénted_chäràacters',
    unicode   => '€_₤_£',
);
my $login = 'some_user';

# Use the default mock configuration
use Act::Config ();
use Test::Act::Config;
$Act::Config::Config = Test::Act::Config->new;

# Load the module to be tested for the methods
require Act::Auth::Password; # 'use' would pick up the unmocked config
# Add the user we're operating on, ignoring any errors
my $schema = Act::Store::Database->instance->schema;
my $users = $schema->resultset('User');
eval { $users->find( { login => $login } )->delete; };
my $user = $schema->resultset('User')->create({
    login => $login,
    # The following fields might vanish if we get a decent login table
    passwd => 'whatever',
    country => 'am',
    email => 'adam@home',
    timezone => 'Europe/Paris',
});


## Tests start here ----------------------------------------------------
# Part 1: Using the current password encryption
while (my ($type,$password) = each %passwords) {
    my $user = $users->find( { login => $login } );
    Act::Auth::Password->set_password($login,$password);
    $user = $users->find( { login => $login } );
    my $crypted = $user->passwd;
    like($user->passwd,qr/^\Q{CRYPT}\E/,
         "$type Password encryption is CRYPT-based");

    Act::Auth::Password->set_password($login,$password);
    $user = $users->find( { login => $login } );
    isnt($user->passwd,$crypted,
         "$type Encryption is properly salted");
    ok(Act::Auth::Password->check_password($login,$password),
       "$type Password is fine");
    eval { Act::Auth::Password->check_password($login,'bad password'); };
    like($@,qr'^Bad password',
       "$type Bad password is rejected");
}

# Part 2: Using MD5 hashes.  Wide characters weren't supported
# back then.
for my $type (qw(ascii iso_latin)) {
    my $user = $users->find( { login => $login } );
    my $password = $passwords{$type};
    my $digest = Digest::MD5->new;
    $digest->add($password);
    my $crypted = $digest->b64digest;
    #    Act::Auth::Password->set_password($login,$crypted);
    $user->passwd($crypted);
    $user->update;
    $user = $users->find( { login => $login } );
    ok(Act::Auth::Password->check_password($login,$password),
       "Legacy $type Password is fine");
    eval { Act::Auth::Password->check_password($login,'bad password'); };
    like($@,qr'^Bad password',
       "Legacy $type Bad password is rejected");
    $user = $users->find( { login => $login } );
    $crypted = $user->passwd;
    like($crypted,qr/^\Q{CRYPT}\E/,
         "Legacy $type Password encryption upgraded");
    ok(Act::Auth::Password->check_password($login,$password),
       "Legacy $type Password is fine after upgrade");
}

CLEANUP:
{ $users->find( { login => $login } )->delete; };
