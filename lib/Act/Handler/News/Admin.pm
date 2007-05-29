use strict;
package Act::Handler::News::Admin;

use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::News;
use Act::Template::HTML;
use Act::Util;

sub handler
{
    # orgas only
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # fetch this conference's news items
    my $news = Act::News->get_items(
                    conf_id => $Request{conference},
                    lang    => $Request{language},
               );

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(news => $news);
    $template->process('news/admin');
}

1;
__END__

=head1 NAME

Act::Handler::News::Admin - create/edit/delete news items

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
