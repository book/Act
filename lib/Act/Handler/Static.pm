#  display "Static" multilingual pages

package Act::Handler::Static;

use strict;
use Apache::Constants qw(NOT_FOUND);
use File::Spec;

use Act::Config;
use Act::Template::HTML;

sub handler
{
    my $template = Act::Template::HTML->new();

    # make sure requested template file exists
    my $file = $Request{path_info};
    my $found;
    for my $dir (@{$template->{INCLUDE_PATH}}) {
        if (-e File::Spec->catfile($dir, $file)) {
            ++$found;
            last;
        }
    }
    if ($found) {
        $template->process($Request{path_info});
    }
    else {
        $Request{status} = NOT_FOUND;
    }
}
1;
__END__

=head1 NAME

Act::Handler::Static - serve multilingual "static" pages

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
