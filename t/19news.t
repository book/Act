use Test::More tests => 9;
use Test::MockObject;
use DateTime;

use Act::Config;
use Act::News;
use Act::Template;

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
$news = Act::News->create(
    conf_id => 'conf',
    user_id => $user->user_id,
    lang    => 'en',
    title   => 'breaking news!',
    text    => 'something interesting',
    datetime => DateTime->now(),
);
isa_ok($news, 'Act::News');

# fetch
my $fetched = Act::News->new(conf_id => 'conf');
is_deeply($fetched, $news, "fetch");

# update
$news->update(text => "something else\nentirely", published => 1);
$fetched = Act::News->new(news_id => $news->news_id);
is_deeply($fetched, $news,"update");

# content
my $expected_content = "<p>something else</p>\n<p>entirely</p>";
is($fetched->content, $expected_content, "content");

# global.news
%Request = ( %Request,
             language   => 'en',
             args       => {},
             conference => 'conf',
           );
$Request{r} = Test::MockObject->new;
$Request{r}->set_true(qw(send_http_header))
           ->set_always(method => 'GET')
           ->set_isa('Apache');
$Config->set(languages => {});
$Config->set(name => { en => 'foobar' });


my $template = Act::Template->new(TRIM => 1);
my $output;
$template->process(\"[% PROCESS common; global.news.size %]", \$output);
is($output, 1, "template - size");
$template->process(\"[% PROCESS common; global.news.0.content %]", \$output);
is($fetched->content, $expected_content, "template - content");


# delete
$news->delete;
is(Act::News->new(news_id => $news->news_id), undef, "News item removed");
