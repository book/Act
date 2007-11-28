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
    my $cnews = Act::News->get_items(
                        conf_id   => $Request{conference},
                        lang      => $Request{language},
                        published => 1,
               );

    my @news;
    my %users;
    my $now = DateTime->now();
    for my $n (@$cnews) {
        # remove items in the future
        next if $n->datetime > $now;

        # fetch title and text, if available in this language
        my $item = $n->items->{$Request{language}};
        next unless $item;
        @$n{keys %$item} = values %$item;

        # fetch user
        $n->{user} = $users{$n->user_id} ||= Act::User->new(user_id => $n->user_id);
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
