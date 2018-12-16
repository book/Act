package Act::Wiki;

use strict;
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::Default;
use DateTime::Format::Pg;

use Act::Config;
use Act::Tag;
use Act::Util;
use Act::Wiki::Formatter;
use Act::Wiki::Store;

sub new
{
    return Wiki::Toolkit->new(
        store     => Act::Wiki::Store->new(
            charset => 'UTF-8',
            map { $_ => $Config->get("wiki_$_") }
                qw(dbhost dbname dbuser dbpass)
        ),
        formatter => Act::Wiki::Formatter->new(),
    );
}
sub format_node
{
    my ($wiki, $template, $content) = @_;

    my %metadata;
    my $cooked = $wiki->format($content, \%metadata);
    if ($metadata{chunks}) {
        $cooked = '[% TAGS {% %} %]' . $cooked;
        my $output;
        $template->variables(chunks => $metadata{chunks});
        $template->process(\$cooked, \$output);
        return $output;
    }
    return $cooked;
}
sub display_node
{
    my ($wiki, $template, $node, $version) = @_;

    my %data = $wiki->retrieve_node(name => make_node_name($node), version => $version);
    $data{last_modified} = DateTime::Format::Pg->parse_datetime($data{last_modified})
        if $data{last_modified};
    undef $version if $version && $data{version} != $version;

    # retrieve tags
    my @tags = Act::Tag->fetch_tags(
                    conf_id     => $Request{conference},
                    type        => 'wiki',
                    tagged_id   => $node,
               );

    # add tags
    if ($Request{user} && $Request{args}{ok}) {
        my %oldtags = map { $_ => 1 } @tags;
        my @newtags = grep !$oldtags{$_}, Act::Tag->split_tags($Request{args}{newtags});
        if (@newtags) {
            Act::Tag->update_tags(
                conf_id     => $Request{conference},
                type        => 'wiki',
                tagged_id   => $node,
                oldtags     => \@tags,
                newtags     => [  @tags, @newtags ],
            );
        }
        Act::Util::redirect(make_uri('wiki', node => $node));
        return;
    }
    my $alltags = Act::Tag->find_tags(
                    conf_id => $Request{conference},
                    type    => 'wiki',
                  );

    $template->variables_raw(content => format_node($wiki, $template, $data{content}));
    $template->variables(node    => $node,
                         data    => \%data,
                         version => $version,
                         tags    => \@tags,
                         alltags => $alltags,
                         author  => Act::User->new( user_id => $data{metadata}{user_id}[0]),
    );
    $template->process('wiki/node');
}
sub make_node_name  { join ';', $Request{conference}, $_[0] }
sub split_node_name { (split ';', $_[0])[1] }

1;
__END__

=head1 NAME

Act::Wiki - Wiki utility routines

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
