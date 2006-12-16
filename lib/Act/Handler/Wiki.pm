#  display "Static" multilingual pages

package Act::Handler::Wiki;

use strict;
use Apache::Constants qw(NOT_FOUND);
use Encode;
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::Default;

use Act::Config;
use Act::Template::HTML;
use Act::Util;
use Act::Wiki::Store;

my %actions = (
    commit  => \&wiki_commit,
    display => \&wiki_display,
    edit    => \&wiki_edit,
);

sub handler
{
    my $action = $Request{args}{action} || 'display';
    unless (exists $actions{$action}) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $wiki = Wiki::Toolkit->new(
        store     => Act::Wiki::Store->new(dbh => $Request{dbh}),
        formatter => Wiki::Toolkit::Formatter::Default->new(node_prefix => 'wiki?node='),
    );
    my $template = Act::Template::HTML->new();
    $actions{$action}->($wiki, $template);
}
sub wiki_display
{
    my ($wiki, $template) = @_;

    my $node = $Request{args}{node} || 'HomePage';
    my %data = $wiki->retrieve_node(name => $node);

    $template->variables_raw(
        data => encode("ISO-8859-1", $wiki->format($data{content})),
    );
    $template->variables(
        node        => $node,
        uri_edit    => self_uri( action => 'edit',
                                 node   => $node,
                               ),
    );
    $template->process('wiki/node');
}
sub wiki_edit
{
    my ($wiki, $template) = @_;

    # logged in users only!
    unless ($Request{user}) {
        $Request{status} = NOT_FOUND;
        return;
    }

    my $node = $Request{args}{node};
    unless ($node) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my %data = $wiki->retrieve_node(name => $node);
    $template->variables(
        node     => $node,
        data     => encode("ISO-8859-1", $data{content}),
        checksum => $data{checksum},
    );
    $template->process('wiki/edit');
}
sub wiki_commit
{
    my ($wiki, $template) = @_;

    # logged in users only!
    unless ($Request{user}) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # store the node
    my $node = $Request{args}{node};
    if ($wiki->write_node(
                  @{$Request{args}}{qw(node content checksum)},
                  {
                   user_id => $Request{user}->user_id,
                  }
                ))
    {
        # display the node again
        wiki_display($wiki, $template);
    }
    else {
        # conflict
        my %data = $wiki->retrieve_node($node);
        $template->variables(
            conflict    => 1,
            node        => $node,
            new_data    => $Request{args}{content},
            data        => encode("ISO-8859-1", $data{content}),
            checksum    => $data{checksum},
        );
        $template->process('wiki/edit');
    }
}
1;
__END__

=head1 NAME

Act::Handler::Wiki - serve wiki pages

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
