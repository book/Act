#!perl -w
use Test::More tests => 2;
use strict;
use Test::Lib;
use Test::Act::Util;   # load the test database

$Request{dbh}->do('CREATE TABLE foo ( bar boolean DEFAULT false )');
$Request{dbh}->commit;

for my $v (0..1) {
    my $sth = $Request{dbh}->prepare('INSERT INTO foo (bar) VALUES (?)');
    $sth->execute($v);
    $Request{dbh}->commit;

    $sth = $Request{dbh}->prepare('SELECT bar FROM foo');
    $sth->execute();
    my ($bar) = $sth->fetchrow_array;
    $sth->finish;
    is($bar, $v);

    $sth = $Request{dbh}->prepare('DELETE FROM foo');
    $sth->execute();
    $Request{dbh}->commit;
}

$Request{dbh}->do('DROP TABLE foo');
