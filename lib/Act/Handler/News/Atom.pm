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

sub handler
{
    # fetch this conference's published news items
    my $news = Act::News->get_items(
                        conf_id   => $Request{conference},
                        lang      => $Request{language},
                        published => 1,
               );

    # generate Atom feed
    my $feed = XML::Atom::Feed->new;
    $feed->title($Config->name->{$Request{language}});
    $feed->id($Config->general_full_uri . $Request{language});
    $feed->language($Request{language});
    $feed->updated(rfc3339(@$news ? $news->[0]->datetime : DateTime->now));

    my $link = XML::Atom::Link->new;
    $link->type('application/atom+xml');
    $link->rel('self');
    $link->href($Config->general_full_uri . "news.xml?language=$Request{language}");
    $feed->add_link($link);

    $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('alternate');
    $link->href($Config->general_full_uri . "news?language=$Request{language}");
    $feed->add_link($link);

    my %authors;
    for my $item (@$news) {
        my $entry = XML::Atom::Entry->new;
        $entry->title($item->title);
        $entry->id($Config->general_full_uri . $item->news_id);
        unless ($authors{$item->user_id}) {
            my $user = Act::User->new(user_id => $item->user_id);
            my $person = XML::Atom::Person->new;
            $person->email($user->email);
            $person->name($user->nick_name || $user->full_name);
            $authors{$item->user_id} = $person;
        }
        $entry->author($authors{$item->user_id});
        $entry->updated(rfc3339($item->datetime));
        $entry->content($item->content);

        $link = XML::Atom::Link->new;
        $link->type('text/html');
        $link->rel('alternate');
        $link->href($Config->general_full_uri . "news?language=$Request{language}");
        $entry->add_link($link);

        $feed->add_entry($entry);
    }
    $Request{r}->send_http_header('application/atom+xml; charset=UTF-8');
    $Request{r}->print($feed->as_xml);
}
sub rfc3339 { shift->iso8601 . 'Z' }

1;
__END__

=head1 NAME

Act::Handler::News::Atom - create Atom feed for news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
