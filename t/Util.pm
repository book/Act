# this is a helper test module
use Act::Config;
use DBI;

$Request{dbh} = DBI->connect(
    $Config->database_test_dsn,
    $Config->database_test_user,
    $Config->database_test_passwd,
    { AutoCommit => 0 }
) or die "can't connect to database: " . $DBI::errstr;

END {
    # clean up
    $Request{dbh}->do("DELETE FROM users;");
    $Request{dbh}->commit;
    $Request{dbh}->disconnect;
}

