use strict;
package Act::Handler::News::Fetch;

use DateTime;

use Act::Config;
use Act::News;
use Act::User;
use Act::Util;

sub fetch
{
    my $count = shift || 0;
    my $news_id = shift;

    # fetch this conference's published news items
    my %args = ( conf_id   => $Request{conference},
                 published => 1,
               );
    $args{news_id} = $news_id if $news_id;
    my $cnews = Act::News->get_items(%args);

    my @news;
    my %users;
    my $now = DateTime->now();
    for my $n (@$cnews) {
        # remove items in the future
        next if $n->datetime > $now;

        # fetch title and text, if available in this language
        my $lang = $Request{language};
        $lang =~ s/_.*//;
        my $item = $n->items->{$lang};
        next unless $item;
        @$n{keys %$item} = values %$item;

        # fetch user
        $n->{user} = $users{$n->user_id} ||= Act::User->new(user_id => $n->user_id);

        # permalink
        $n->{link} = $Config->general_full_uri . 'news/' . $n->{news_id};

        push @news, $n;
    }
    # apply optional limit
    $#news = $count - 1 if $count && @news > $count;
    return \@news;
}

1;
__END__

=head1 NAME

Act::Handler::News::Fetch - fetch news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
