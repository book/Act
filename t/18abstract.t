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

my @tests = (
  # name      input         expected
  [ 'empty',        '',                  [ ]                                                           ],
  [ 'string',       'foo',               [ { text => 'foo' } ]                                         ],
  [ 'user',         "user:$uid",         [ { text => '' }, { user => $user } ]                         ],
  [ 'talk',         "talk:$tid",         [ { text => '' }, { talk => $talk, user => $user } ]          ],
  [ 'mixed',        "foo user:$uid bar", [ { text => 'foo ' }, { user => $user }, { text => ' bar' } ] ],
  [ 'unknown user', 'user:9999',         [ { text => '' }, { text => 'user:9999' } ]                   ],
  [ 'unknown talk', 'talk:9999',         [ { text => '' }, { text => 'talk:9999' } ]                   ],
);

plan tests => scalar(@tests);

for my $test (@tests) {
    my ($name, $input, $expected) = @$test;
    my $chunked = Act::Abstract::chunked($input);
    is_deeply($chunked, $expected, $name);
}
