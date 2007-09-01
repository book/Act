use Test::More tests => 15;

use Act::Config;
use Act::Tag;

use strict;
use t::Util;

# create an empty tag
my $tag = Act::Tag->new();
isa_ok($tag, 'Act::Tag');
is_deeply($tag, {}, "create empty tag with new()");

# create a tag
$tag = Act::Tag->create(
    conf_id     => 'conf',
    tag         => 'foobar',
    type        => 'wiki',
    tagged_id   => 'conf/HomePage',
);
isa_ok($tag, 'Act::Tag');

# fetch
my $fetched = Act::Tag->new(conf_id => 'conf');
is_deeply($tag, $tag, "fetch");

# update
$tag->update(type => 'talk', tagged_id => 42);
$fetched = Act::Tag->new(tag_id => $tag->tag_id);
is_deeply($fetched, $tag, "update");

# delete
$tag->delete;
is(Act::Tag->new(tag_id => $tag->tag_id), undef, "Tag removed");

# update_tags / fetch_tags
my %key = (
    conf_id     => 'conf',
    type        => 'talk',
    tagged_id   => 42,
);
Act::Tag->update_tags(%key, newtags => [ qw(foo bar) ]);
my @tags = Act::Tag->fetch_tags(%key);
is_deeply(\@tags, [ qw(bar foo) ], 'fetch_tags');

Act::Tag->update_tags(%key, oldtags => [ qw(foo bar) ], newtags => [ qw(foo baz) ]);
@tags = Act::Tag->fetch_tags(%key);
is_deeply(\@tags, [ qw(baz foo) ], 'fetch_tags');

# find_tagged
delete $key{tagged_id};
my %key2 = (%key, tagged_id => 43);
Act::Tag->update_tags(%key2, newtags => [ qw(foo bar) ]);

my @ids = Act::Tag->find_tagged(%key, tags => ['foo']);
is_deeply(\@ids, [ 42, 43 ], 'find_tagged');
@ids = Act::Tag->find_tagged(%key, tags => ['bar']);
is_deeply(\@ids, [ 43 ], 'find_tagged');
@ids = Act::Tag->find_tagged(%key, tags => ['baz']);
is_deeply(\@ids, [ 42 ], 'find_tagged');
@ids = Act::Tag->find_tagged(%key, tags => ['tut']);
is_deeply(\@ids, [ ], 'find_tagged');

# find_tags
my $tags = Act::Tag->find_tags(%key);
is_deeply($tags, [ [bar => 1],[baz => 1],[foo => 2] ], 'find_tags');
$tags = Act::Tag->find_tags(%key, filter => [ 42 ]);
is_deeply($tags, [ [baz => 1],[foo => 1] ], 'find_tags filtered');

# split_tags
is_deeply( [ Act::Tag->split_tags(' foo bar foo ') ], [ qw(bar foo) ], "split_tags");
