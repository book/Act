package Act::Wiki;

use strict;
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::Default;
use Encode;

use Act::Config;
use Act::Wiki::Store;

sub new
{
    return Wiki::Toolkit->new(
        store     => Act::Wiki::Store->new(map { $_ => $Config->get("wiki_$_") }
                                           qw(dbname dbuser dbpass)),
        formatter => Wiki::Toolkit::Formatter::Default->new(
                        extended_links  => 1,
                        implicit_links  => 1,
                        node_prefix => 'wiki?node=',
                     ),
    );
}
sub display_node
{
    my ($wiki, $template, $node, $version) = @_;

    my %data = $wiki->retrieve_node(name => $node, version => $version);

    $template->variables_raw(
        content => encode("ISO-8859-1", $wiki->format($data{content})),
    );
    $template->variables(node    => $node,
                         data    => \%data,
                         version => $version,
    );
    $template->process('wiki/node');
}
1;
__END__

=head1 NAME

Act::Wiki - Wiki utility routines

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
