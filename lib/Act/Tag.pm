package Act::Tag;
use strict;
use Act::Object;
use base qw( Act::Object );

use HTML::TagCloud;
use URI::Escape;

use Act::Config;

use constant DEBUG => !$^C && $Config->database_debug;

# class data used by Act::Object
our $table       = 'tags';
our $primary_key = 'tag_id';

our %sql_stub    = (
    select => "t.*",
    from   => "tags t",
);
our %sql_mapping = (
    # standard stuff
    map( { ($_, "(t.$_=?)") }
         qw( tag_id conf_id tag type tagged_id) )
);
our %sql_opts = ( 'order by' => 'tag' );

sub fetch_tags
{
    my ($class, %args) = @_;
    my $tags = $class->get_items(%args);
    return sort map $_->{tag}, @$tags;
}
sub update_tags
{
    my ($class, %args) = @_;

    my %oldtags = map { $_ => 1 } @{ $args{oldtags} || [] };
    my %newtags = map { $_ => 1 } @{ $args{newtags} || [] };

    # delete old tags not in new
    for my $tag (keys %oldtags) {
        unless ($newtags{$tag}) {
            $class->new(
                tag => $tag,
                map { $_ => $args{$_} } qw(conf_id type tagged_id)
            )->delete;
        }
    }
    # add new items not in old
    for my $tag (keys %newtags) {
        unless ($oldtags{$tag}) {
            $class->create(
                tag => $tag,
                map { $_ => $args{$_} } qw(conf_id type tagged_id)
            );
        }
    }
}
sub find_tagged
{
    my ($class, %args) = @_;
    my @tags = @{ $args{tags} };
    my $SQL = 'SELECT DISTINCT tagged_id FROM tags'
            . ' WHERE conf_id = ? AND type = ?'
            . ' AND tag IN (' . join(',', ('?') x @tags) . ')';
    my @values = ( $args{conf_id}, $args{type}, @tags );
    Act::Object::_sql_debug($SQL, @values) if DEBUG;
    my $sth = $Request{dbh}->prepare($SQL);
    $sth->execute(@values);
    my $result = $sth->fetchall_arrayref([]);
    return sort map $_->[0], @$result;
}
sub find_tags
{
    my ($class, %args) = @_;
    return [] if $args{filter} && !@{$args{filter}};
    my $SQL = 'SELECT tag, COUNT(tag) FROM tags'
            . ' WHERE conf_id = ? AND type = ?';
    my @values = ( $args{conf_id}, $args{type} );
    if ($args{filter}) {
        $SQL .= ' AND tagged_id IN (' . join(',',('?') x @{$args{filter}}) . ')';
        push @values, @{$args{filter}};
    }
    $SQL .= ' GROUP BY tag ORDER BY tag';
    Act::Object::_sql_debug($SQL, @values) if DEBUG;
    my $sth = $Request{dbh}->prepare($SQL);
    $sth->execute(@values);
    return $sth->fetchall_arrayref([]);
}
sub get_cloud
{
    my ($class, %args) = @_;
    my $tags = $class->find_tags(%args);
    my $cloud = HTML::TagCloud->new;
    for my $t (@$tags) {
        my ($tag, $count) = @$t;
        my $url = join '/', $Request{r}->uri, 'tag', URI::Escape::uri_escape_utf8($tag);
        $cloud->add($tag, $url, $count);
    }
    return $cloud->html_and_css;
}
sub split_tags
{
    my ($class, $string) = @_;
    my %seen;
    return sort
           map Act::Util::normalize($_),
           grep $_ && !$seen{$_}++,
           split /[^\w.]+/, $string;
}

=head1 NAME

Act::Tag - An Act object representing a tag, and a set of tags

=head1 SYNOPSIS

    # get tags for a given object
    my @tags = Act::Tag->fetch_tags(
                conf_id     => $Request{conference},
                type        => 'talk',
                tagged_id   => $talk_id,
    );
    # update a given object's tags
    Act::Tag->update_tags(
                conf_id     => $Request{conference},
                type        => 'talk',
                tagged_id   => $talk_id,
                oldtags     => [ qw(foo bar baz) ],
                newtags     => [ qw(bar fly)],
    );
    # get all objects with given tags (ORed)
    my @talk_ids = Act::Tag->find_tagged(
                conf_id     => $Request{conference},
                type        => 'talk',
                tags        => [ 'foo', 'bar' ],
    );
    # get all tags and object counts
    my $weighted_tags = Act::Tag->find_tags(
                conf_id     => $Request{conference},
                type        => 'wiki',
    );
    # get all tags and object counts, filtered against
    # a list of eligible tagged_ids
    my $weighted_tags = Act::Tag->find_tags(
                conf_id     => $Request{conference},
                type        => 'talk',
                filter      => \@talk_ids,
    );

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
