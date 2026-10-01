# this is a helper test module
use Act::Config;
use DBI;
use Act::Talk;
use Act::User;
use Act::Event;

use Test::More;

if (my $dsn = $Config->database_test_dsn) {

    if ($Config->database_test_host) {
        $dsn .= ";host=" . $Config->database_test_host;
    }

    $Request{dbh} = DBI->connect(
        $dsn,
        $Config->database_test_user,
        $Config->database_test_passwd,
        { AutoCommit => 0,
          pg_enable_utf8 => 1,
        }
    );
    ok($Request{dbh}, "We have a test database");
    $Request{dbh}->do("DELETE FROM $_")
        for qw(events invoice_num invoices news_items news order_items orders
               participations rights user_talks talks users bios tags);
}
else {
    plan skip_all => "Unable to run tests without a DB";
}

# fill the database with simple default data
sub db_add_users {
    Act::User->create(
        login   => 'book',
        passwd  => 'BOOK',
        email   => 'book@yyy.zzz',
        country => 'fr',
        first_name => 'Philippe',
        last_name  => 'Bruhat',
        pseudonymous => 'f',
        timezone => 'Europe/Paris',
    );
    Act::User->create(
        login   => 'echo',
        passwd  => 'ECHO',
        email   => 'echo@yyy.zzz',
        country => 'fr',
        nick_name => 'echo',
        first_name => 'Eric',
        last_name  => 'Cholet',
        timezone => 'Europe/Paris',
    );
    Act::User->create(
        login   => 'foo',
        passwd  => 'FOO',
        email   => 'foo@bar.com',
        country => 'en',
        timezone => 'Europe/Paris',
    );
    Act::User->create(
        login   => 'user',
        passwd  => 'UZer',
        email   => 'user@example.com',
        country => 'uk',
        timezone => 'Europe/Paris',
    );

    # add participations as well
    my $sth = $Request{dbh}->prepare_cached("INSERT INTO participations (user_id,conf_id,ip,datetime) VALUES(?,?,?,?);");
    $sth->execute( Act::User->new( login => 'book' )->user_id, 'conf',    '127.0.0.1', '2007-02-10 11:22:33' );
    $sth->execute( Act::User->new( login => 'echo' )->user_id, 'conf',    '127.0.0.2', '2007-02-11 18:05:47' );
    $sth->execute( Act::User->new( login => 'user' )->user_id, 'newconf', '127.0.0.3', '2007-02-10 23:58:59' );
    $sth->finish();
}

# must be called after db_add_users
sub db_add_talks {
    Act::Talk->create(
        title     => 'First talk',
        user_id   => Act::User->new( login => 'book' )->user_id,
        conf_id   => 'conf',
        lightning => 'false',
        accepted  => 'false',
        confirmed => 'false',
        duration  => 10,
    );
    Act::Talk->create(
        title     => 'Second talk',
        user_id   => Act::User->new( login => 'book' )->user_id,
        conf_id   => 'conf',
        lightning => 'true',
        accepted  => 'true',
        confirmed => 'false',
        duration  => 5,
    );
    Act::Talk->create(
        title     => 'My talk',
        user_id   => Act::User->new( login => 'echo' )->user_id,
        conf_id   => 'conf',
        lightning => 'false',
        accepted  => 'true',
        confirmed => 'false',
        duration  => 20,
    );
    
}

sub db_add_events {
    Act::Event->create(
        title    => 'Lunch',
        duration => 90,
        conf_id  => 'conf',
        title    => 'Lunch',
        abstract => 'Lunch, outside of the conference premises',
        room     => 'out',
    );
}

# export the subs
{
    no strict 'refs';
    *{caller()."::$_"} = \&{$_} for qw( add_db_users add_db_talks );
}


END {
    if ($Request{dbh}) {
        $Request{dbh}->commit;
        $Request{dbh}->disconnect;
    }
}

1;

