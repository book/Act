use Test::More tests => 3;
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
        registered  => '0',
        tshirt_size => undef,
        nb_family   => '0',
        payment     => undef,
    }, "Correct participation information"
);

# check the user's talks
$user = Act::User->get_items( login => 'book', conf_id => 'conf' )->[0];
is_deeply( $user,
    {
        monk_id      => undef,
        session_id   => undef,
        town         => undef,
        nick_name    => undef,
        gpg_pub_key  => undef,
        last_name    => 'Bruhat',
        email        => 'book@yyy.zzz',
        email_hide   => '1',
        bio          => undef,
        civility     => undef,
        country      => 'fr',
        web_page     => undef,
        timezone     => 'Europe/Paris',
        language     => undef,
        pause_id     => undef,
        has_talk    => '1',
        has_paid     => '0',
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
    }, "Got the user and the new fields" );

my $user2 = Act::User->new( login => 'book', conf_id => 'conf' );
is_deeply( $user2, $user, "Same user with new()" );

