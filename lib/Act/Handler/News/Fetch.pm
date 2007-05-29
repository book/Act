use strict;
package Act::Handler::News::Fetch;

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
    # apply optional limit
    $#$news = $count - 1 if $count && @$news > $count;

    # fetch users
    $_->{user} = Act::User->new(user_id => $_->user_id) for @$news;

    return $news;
}

1;
__END__

=head1 NAME

Act::Handler::News::Fetch - fetch news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
