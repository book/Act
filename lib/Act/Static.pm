#  display "Static" multilingual pages

package Act::Static;

use strict;

use Act::Config;
use Act::Template::HTML;

sub handler
{
    my $template = Act::Template::HTML->new();
    $template->process($Request{path_info});
}
1;
__END__

=head1 NAME

Act::Static - serve multilingual "static" pages

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
