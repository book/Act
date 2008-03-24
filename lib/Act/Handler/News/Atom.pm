use strict;
package Act::Handler::News::Atom;

use DateTime;
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::Atom::Link;
$XML::Atom::DefaultVersion = "1.0";

use Act::Config;
use Act::News;
use Act::User;
use Act::Handler::News::Fetch;

sub handler
{
    # retrieve language from path info
    if ($Request{path_info} =~ /^(\w+)\.xml$/
        && exists $Config->languages->{$1})
    {
        $Request{language} = $1;
    }
    # fetch this conference's published news items
    my $news = Act::Handler::News::Fetch::fetch();

    # generate Atom feed
    my $url = $Config->general_full_uri . "atom/$Request{language}.xml";
    my $feed = XML::Atom::Feed->new;
    $feed->title($Config->name->{$Request{language}});
    $feed->id($url);
    $feed->language($Request{language});
    $feed->updated(rfc3339(@$news ? $news->[0]->datetime : DateTime->now));

    add_link($feed,
             type => 'application/atom+xml',
             rel  => 'self',
             href => $url);

    add_link($feed,
             type => 'text/html',
             rel  => 'alternate',
             href => $Config->general_full_uri . "news?language=$Request{language}");

    my %authors;
    for my $item (@$news) {
        my $entry = XML::Atom::Entry->new;
        $entry->title($item->title);
        $entry->id($Config->general_full_uri . $Request{language} . '/' . $item->news_id);
        unless ($authors{$item->user_id}) {
            my $person = XML::Atom::Person->new;
            $person->email($item->{user}->email);
            $person->name($item->{user}->nick_name || $item->{user}->full_name);
            $authors{$item->user_id} = $person;
        }
        $entry->author($authors{$item->user_id});
        $entry->updated(rfc3339($item->datetime));
        $entry->content($item->content);

        add_link($entry,
                 type => 'text/html',
                 rel  => 'alternate',
                 href => $item->{link});

        $feed->add_entry($entry);
    }
    $Request{r}->send_http_header('application/atom+xml; charset=UTF-8');
    $Request{r}->print($feed->as_xml);
}

sub rfc3339 { shift->iso8601 . 'Z' }

sub add_link
{
    my ($thing, @args) = @_;

    my $link = XML::Atom::Link->new;
    while (my ($method, $value) = splice(@args,0,2)) {
        $link->$method($value);
    }
    $thing->add_link($link);
}
1;
__END__

=head1 NAME

Act::Handler::News::Atom - create Atom feed for news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
