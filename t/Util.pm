# this is a helper test module
use Act::Config;
use DBI;
use Act::Talk;
use Act::User;

$Request{dbh} = DBI->connect(
    $Config->database_test_dsn,
    $Config->database_test_user,
    $Config->database_test_passwd,
    { AutoCommit => 0 }
) or die "can't connect to database: " . $DBI::errstr;

# clean up before
$Request{dbh}->do("DELETE FROM rights");
$Request{dbh}->do("DELETE FROM participations");
$Request{dbh}->do("DELETE FROM talks");
$Request{dbh}->do("DELETE FROM users");
$Request{dbh}->do("DELETE FROM news");
$Request{dbh}->do("DELETE FROM translations");

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
        talk_id   => 1,
        user_id   => Act::User->new( login => 'book' )->user_id,
        conf_id   => 'conf',
        lightning => 'false',
        accepted  => 'false',
        confirmed => 'false',
        duration  => 10,
    );
    Act::Talk->create(
        title     => 'Second talk',
        talk_id   => 2,
        user_id   => Act::User->new( login => 'book' )->user_id,
        conf_id   => 'conf',
        lightning => 'true',
        accepted  => 'true',
        confirmed => 'false',
        duration  => 5,
    );
    Act::Talk->create(
        title     => 'My talk',
        talk_id   => 3,
        user_id   => Act::User->new( login => 'echo' )->user_id,
        conf_id   => 'conf',
        lightning => 'false',
        accepted  => 'true',
        confirmed => 'false',
        duration  => 20,
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

