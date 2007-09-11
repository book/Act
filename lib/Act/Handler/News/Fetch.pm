use strict;
package Act::Handler::News::Fetch;

use DateTime;

use Act::Config;
use Act::News;
use Act::User;

sub fetch
{
    my $count = shift || 0;

    # fetch this conference's published news items
    my $news = Act::News->get_items(
                        conf_id   => $Request{conference},
                        lang      => $Request{language},
                        published => 1,
               );

    # remove items in the future
    my $now = DateTime->now();
    $news = [ grep { $_->datetime <= $now } @$news ];

    # apply optional limit
    $#$news = $count - 1 if $count && @$news > $count;

    for my $n (@$news) {
        # fetch user
        $n->{user} = Act::User->new(user_id => $n->user_id);
        # fetch title and text
        my $item = $n->items->{$Request{language}};
        $n->{$_} = $item->{$_} for qw(title text);
    }
    return $news;
}

1;
__END__

=head1 NAME

Act::Handler::News::Fetch - fetch news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
