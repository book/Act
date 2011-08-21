use Test::More tests => 16;
use Test::MockObject;
use DateTime;

use Act::Config;
use Act::News;
use Act::Template;

use strict;
use t::Util;

$Config->set(general_full_uri => 'http://example.com/conf/');

# create an empty news item
my $news = Act::News->new();
isa_ok($news, 'Act::News');
is_deeply($news, {}, "create empty news item with new()");

# load some users
db_add_users();
my $user = Act::User->new( login => 'echo' );

# create a news item
my %items = ( en => { title => 'breaking news!',
                      text  => 'something interesting' } );
$news = Act::News->create(
    conf_id => 'conf',
    user_id => $user->user_id,
    items   => \%items,
    datetime => DateTime->now(),
);
isa_ok($news, 'Act::News');

# new
my $fetched = Act::News->new(conf_id => 'conf');
is_deeply($fetched, $news, "fetch");
is_deeply($fetched->items, \%items, "items");

# update
$items{en}{text} = "something else\n\nentirely";
$news->update(items => \%items, published => 1);
$fetched = Act::News->new(news_id => $news->news_id);
is_deeply($fetched, $news,"update");
is_deeply($fetched->items, \%items, "updated items");

# fetch
$Request{language} = 'en';
require_ok('Act::Handler::News::Fetch');
$fetched = Act::Handler::News::Fetch::fetch();
isa_ok($fetched, 'ARRAY', "fetch");
is(scalar(@$fetched), 1, "fetched 1");
$fetched = $fetched->[0];
is($fetched->{news_id}, $news->news_id, "fetch news_id");

# content
my $expected_content = "<p>something else</p>\n<p>entirely</p>";
is($fetched->content, $expected_content, "content");
is(Act::News->content($fetched->text), $expected_content, "content as class method");

# global.news
%Request = ( %Request,
             language   => 'en',
             args       => {},
             conference => 'conf',
           );
$Request{r} = Test::MockObject->new;
$Request{r}->set_true(qw(send_http_header))
           ->set_always(method => 'GET')
           ->set_isa('Act::Request');
$Config->set(languages => {});
$Config->set(name => { en => 'foobar' });


my $template = Act::Template->new(TRIM => 1);
my $output;
$template->process(\"[% global.news.size %]", \$output);
is($output, 1, "template - size");
$template->process(\"[% global.news.0.content %]", \$output);
is($fetched->content, $expected_content, "template - content");

# delete
$news->delete(items => \%items);
is(Act::News->new(news_id => $news->news_id), undef, "News item removed");
