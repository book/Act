use Test::More tests => 7;
use DateTime;
use Act::News;
use strict;
use t::Util;

# create an empty news item
my $news = Act::News->new();
isa_ok($news, 'Act::News');
is_deeply($news, {}, "create empty news item with new()");

# load some users
db_add_users();
my $user = Act::User->new( login => 'echo' );

# create a news item
my $now = DateTime->now();
$news = Act::News->create(
    conf_id => 'conf',
    user_id => $user->user_id,
    lang    => 'en',
    title   => 'breaking news!',
    text    => 'something interesting',
);
isa_ok($news, 'Act::News');

# fetch
my $fetched = Act::News->new(conf_id => 'conf');
is_deeply($fetched, $news, "fetch");

# update
$now = DateTime->now();
$news->update(text => "something else\nentirely");
$fetched = Act::News->new(news_id => $news->news_id);
is_deeply($fetched, $news,"update");

# content
is($fetched->content, "<p>something else</p>\n<p>entirely</p>", "content");

# delete
$news->delete;
is(Act::News->new(news_id => $news->news_id), undef, "News item removed");
