use Test::More tests => 5;
use strict;
use t::Util;
use Act::Talk;
use Act::User;

# load some users & talks
db_add_users();
db_add_talks();
$Request{conference} = 'conf';

my $user = Act::User->new( login => 'book' );
is_deeply(
    $user->participation,
    {
        conf_id     => 'conf',
        user_id     => $user->user_id,
        tshirt_size => undef,
        nb_family   => '0',
        ip          => '127.0.0.1',
        datetime    => '2007-02-10 11:22:33',
    }, "Correct participation information"
);

# check the user's talks
$user = Act::User->get_items( login => 'book', conf_id => 'conf' )->[0];
is_deeply( $user,
    {
        monk_id      => undef,
        monk_name    => undef,
        session_id   => undef,
        town         => undef,
        nick_name    => undef,
        gpg_key_id   => undef,
        last_name    => 'Bruhat',
        email        => 'book@yyy.zzz',
        email_hide   => '1',
        salutation   => undef,
        country      => 'fr',
        web_page     => undef,
        timezone     => 'Europe/Paris',
        language     => undef,
        pause_id     => undef,
        #has_talk    => '1',
        #has_paid     => '0',
        login        => 'book',
        passwd       => 'BOOK',
        pm_group     => undef,
        pseudonymous => '0',
        pm_group_url => undef,
        user_id      => $user->user_id,
        first_name   => 'Philippe',
        im           => undef,
        photo_name   => undef,
        committed    => '1',
        address      => undef,
        company      => undef,
        company_url  => undef,
        vat          => undef,
    }, "Got the user and the new fields" );

my $user2 = Act::User->new( login => 'book', conf_id => 'conf' );
is_deeply( $user2, $user, "Same user with new()" );

is( $user->has_talk, 2, "has_talk" );
is( $user->has_paid, 0, "has_paid" );

