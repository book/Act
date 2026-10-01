#!/usr/bin/env perl
use strict;
use warnings;
use Act::Track;
use Test::Lib;
use Test::Act::Util;
use Test::More;

# manually insert a track
my $sth = $Request{dbh}->prepare_cached("INSERT INTO tracks (conf_id,title,description) VALUES(?,?,?)");
$sth->execute( 'conf', 'DB', 'Databases' );
$sth->finish();

# there is only one row
$sth = $Request{dbh}->prepare_cached("SELECT * from tracks LIMIT 1");
$sth->execute();
my $hash = $sth->fetchrow_hashref;
$sth->finish;

my $track = Act::Track->new( track_id => $hash->{track_id} );
isa_ok( $track, 'Act::Track' );
is_deeply( $track, $hash, "Can insert a track" );

$track = Act::Track->new();
isa_ok( $track, 'Act::Track' );
is_deeply( $track, {}, "create empty track with new()" );

# create a track
$track = Act::Track->create(
   title     => 'test',
   conf_id   => 'conf',
);
isa_ok( $track, 'Act::Track' );

# fetch a track
my $id = $track->track_id;
my $track2 = Act::Track->new( track_id => $id );
$track2->update( title => 'new test' );

$track = Act::Track->new( track_id => $id );
is_deeply( $track, $track2, "field modified by update" );

# try deleting the track
$track->delete;

is( Act::Track->new( track_id => $id ), undef, "Track removed" );

done_testing();
