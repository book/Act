package Act::Handler::Wiki;

use strict;
use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Template::HTML;
use Act::Util;
use Act::Wiki;

sub handler
{
    my $wiki     = Act::Wiki->new();
    my $template = Act::Template::HTML->new();
    my $node = $Request{args}{node} || 'HomePage';
    Act::Wiki::display_node($wiki, $template, $node);
}
1;
__END__

=head1 NAME

Act::Handler::Wiki - display wiki pages

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
