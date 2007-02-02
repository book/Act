package Act::Wiki;

use strict;
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::Default;

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
    my ($wiki, $template, $node) = @_;

    my %data = $wiki->retrieve_node(name => $node);

    $template->variables_raw(
        data => encode("ISO-8859-1", $wiki->format($data{content})),
    );
    $template->variables(
        node        => $node,
        uri_edit    => make_uri('wikiedit', action => 'edit', node => $node),
        uri_recent  => make_uri('wiki',     action => 'recent'),
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
