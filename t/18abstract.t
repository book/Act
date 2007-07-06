use Test::More;
use strict;
use t::Util;
use Act::Talk;
use Act::User;
use Act::Abstract;
use DateTime;

# create user and talk
$Request{conference} = 'conf'; # needed by has_talk
db_add_users();
db_add_talks();
my $user = Act::User->new(login => 'echo');
my $talk = Act::Talk->new(title => 'My talk');

my $uid = $user->user_id;
my $tid = $talk->talk_id;

my @user_tests = (
  # name                input           expected
  [ 'empty',            '',             undef ],
  [ 'unknown user',     9999,           undef ],
  [ 'user_id',          $uid,           $user ],
  [ 'nick_name',        'echo',         $user ],
  [ 'first/last name',  'Eric Cholet',  $user ],
);
my @chunked_tests = (
  # name            input                expected
  [ 'empty',        '',                  [ ]                                                           ],
  [ 'string',       'foo',               [ { text => 'foo' } ]                                         ],
  [ 'user',         "user:$uid",         [ { text => '' }, { user => $user } ]                         ],
  [ 'talk',         "talk:$tid",         [ { text => '' }, { talk => $talk, user => $user } ]          ],
  [ 'mixed',        "foo user:$uid bar", [ { text => 'foo ' }, { user => $user }, { text => ' bar' } ] ],
  [ 'unknown user', 'user:9999',         [ { text => '' }, { text => 'user:9999' } ]                   ],
  [ 'unknown talk', 'talk:9999',         [ { text => '' }, { text => 'talk:9999' } ]                   ],
);

plan tests => scalar(@user_tests) + scalar(@chunked_tests);

for my $test (@user_tests) {
    my ($name, $input, $expected) = @$test;
    my $got_user = Act::Abstract::expand_user($input);
    is_deeply($got_user, $expected, $name);
}
    
for my $test (@chunked_tests) {
    my ($name, $input, $expected) = @$test;
    my $chunked = Act::Abstract::chunked($input);
    is_deeply($chunked, $expected, $name);
}
