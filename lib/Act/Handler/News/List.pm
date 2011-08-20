use strict;
package Act::Handler::News::List;
use parent 'Act::Handler';

use Act::Config;
use Act::Handler::News::Fetch;
use Act::Template::HTML;

sub handler
{
    # retrieve optional news_id
    my $news;
    my $news_id = $Request{path_info};
    if ($news_id) {
        unless ($news_id =~ /^\d+$/) {
            $Request{status} = 404;
            return;
        }
        $news = Act::Handler::News::Fetch::fetch(1, $news_id);
        unless (@$news) {
            $Request{status} = 404;
            return;
        }
    }
    else {
        # fetch this conference's published news items
        $news = Act::Handler::News::Fetch::fetch();
    }
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
    return;
}

1;
__END__

=head1 NAME

Act::Handler::News::List - display news page

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
