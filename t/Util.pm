# this is a helper test module
use Act::Config;
use DBI;
use Act::Talk;
use Act::User;
use Act::Event;

$Request{dbh} = DBI->connect(
    $Config->database_test_dsn,
    $Config->database_test_user,
    $Config->database_test_passwd,
    { AutoCommit => 0 }
) or die "can't connect to database: " . $DBI::errstr;

# clean up before
$Request{dbh}->do("DELETE FROM $_")
    for qw(events invoice_num invoices news orders participations rights talks translations users bios );

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
    );
    Act::User->create(
        login   => 'echo',
        passwd  => 'ECHO',
        email   => 'echo@yyy.zzz',
        country => 'fr',
    );
    Act::User->create(
        login   => 'foo',
        passwd  => 'FOO',
        email   => 'foo@bar.com',
        country => 'en',
    );
    Act::User->create(
        login   => 'user',
        passwd  => 'UZer',
        email   => 'user@example.com',
        country => 'uk',
    );

    # add participations as well
    my $sth = $Request{dbh}->prepare_cached("INSERT INTO participations (user_id,conf_id) VALUES(?,?);");
    $sth->execute( Act::User->new( login => 'book' )->user_id, 'conf' );
    $sth->execute( Act::User->new( login => 'echo' )->user_id, 'conf' );
    $sth->execute( Act::User->new( login => 'user' )->user_id, 'newconf' );
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
    $Request{dbh}->commit;
    $Request{dbh}->disconnect;
}

1;

