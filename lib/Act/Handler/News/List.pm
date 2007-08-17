use strict;
package Act::Handler::News::List;

use Act::Config;
use Act::Handler::News::Fetch;
use Act::Template::HTML;

sub handler
{
    # fetch this conference's published news items
    my $news = Act::Handler::News::Fetch::fetch();

    # convert to local time
    for (@$news) {
        $_->datetime->set_time_zone('UTC');
        $_->datetime->set_time_zone($Config->general_timezone);
    }
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables_raw(texts => [ map $_->content, @$news ]);
    $template->variables(news => $news);
    $template->process('news/list');
}

1;
__END__

=head1 NAME

Act::Handler::News::List - display news page

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
