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
