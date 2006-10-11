use Test::More tests => 10;
use strict;
use t::Util;
use Act::Talk;
use Act::User;
use Act::Abstract;
use DateTime;

# load some users
db_add_users();
$Request{conference} = 'conf'; # needed by has_talk

my @users = map Act::User->new(login => $_), qw(book echo);
my @talks = map Act::Talk->create(
   title     => "test $_",
   user_id   => $users[$_]->user_id,
   conf_id   => 'conf',
   duration  => 5,
   lightning => 'true',
   accepted  => '0',
   confirmed => 'false',
   datetime  => DateTime->new( year => 2004, month => 10, day => 16, hour => 16, minute => 0),
), 0..$#users;

for my $talk (@talks) {
    my $chunked =  Act::Abstract::chunked('talk:' . $talk->talk_id);
    isa_ok($chunked, 'ARRAY');
    my ($htext, $htalk) = @$chunked;
    isa_ok($htext, 'HASH');
    isa_ok($htalk, 'HASH');
    isa_ok($htalk->{talk}, 'Act::Talk');
    is($htalk->{talk}->talk_id, $talk->talk_id);
}
