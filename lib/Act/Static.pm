#  display "Static" multilingual pages

package Act::Static;

use strict;

use Act::Config;
use Act::Template;

sub handler
{
    my $template = Act::Template->new();
    $Request{r}->send_http_header('text/html');
    $template->process($Request{path_info}, $Request{r});
}
1;
