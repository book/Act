package Act::Handler::Wiki;

use strict;
use 'Act::Handler';

use DateTime;
use DateTime::Format::Pg;
use Encode;
use Text::Diff ();

use Act::Config;
use Act::Template::HTML;
use Act::Tag;
use Act::User;
use Act::Util;
use Act::Wiki;

my %actions = (
    display => \&wiki_display,
    recent  => \&wiki_recent,
    history => \&wiki_history,
    diff    => \&wiki_diff,
    help    => \&wiki_help,
    tags    => \&wiki_tags,
);

sub handler
{
    my ($action, @args);
    if ($Request{path_info}) {
        my ($type, $tag) = split '/', $Request{path_info};
        if ($type eq 'tag' && $tag) {
            $action = 'tags';
            @args = ( $tag );
        }
    }
    else {
        $action = $Request{args}{action} || 'display';
    }
    unless (exists $actions{$action}) {
        $Request{status} = 404;
        return;
    }
    my $wiki     = Act::Wiki->new();
    my $template = Act::Template::HTML->new();
    $actions{$action}->($wiki, $template, @args);
    return;
}

# display a specific node (wiki page)
sub wiki_display
{
    my ($wiki, $template) = @_;
    my $node = $Request{args}{node} || 'HomePage';
    Act::Wiki::display_node($wiki, $template, $node, $Request{args}{version});
}

# list of recent changes
sub wiki_recent
{
    my ($wiki, $template) = @_;

    # default period is 1 week
    my $period = $Request{args}{period};
    $period ||= '1weeks';

    # convert start of period to epoch
    my ($quant, $unit) = $period =~ /^(\d)(.*)$/;
    $quant ||= 1;
    $unit  ||= 'weeks';

    my $date = DateTime->now;
    $date->subtract( $unit => $quant);

    my @nodes = grep { ( split /;/, $_->{name})[0] eq $Request{conference} }
                $wiki->list_recent_changes(since => $date->epoch);
    for my $node (@nodes) {
        $node->{user} = Act::User->new( user_id => $node->{metadata}{user_id}[0]);
        $node->{name} = Act::Wiki::split_node_name(Encode::decode_utf8($node->{name}));
        $node->{last_modified} = DateTime::Format::Pg->parse_datetime($node->{last_modified});
    }
    $template->variables(
        nodes  => \@nodes,
        period => $quant . $unit,
        alltags => Act::Tag->find_tags(
                        conf_id => $Request{conference},
                        type    => 'wiki',
                   ),
    );
    $template->process('wiki/recent');
}

# page history
sub wiki_history
{
    my ($wiki, $template) = @_;

    my $node = $Request{args}{node};
    unless ($node) {
        $Request{status} = 404;
        return;
    }

    my @versions = $wiki->list_node_all_versions(name => Act::Wiki::make_node_name($node), with_metadata => 1);
    for my $v (@versions) {
        $v->{user} = Act::User->new(user_id => $v->{metadata}{user_id});
        $v->{last_modified} = DateTime::Format::Pg->parse_datetime($v->{last_modified});
    }
    $template->variables(
        node     => $node,
        versions => \@versions,
    );
    $template->process('wiki/history');
}

sub wiki_diff
{
    my ($wiki, $template) = @_;

    my $node = $Request{args}{node};

    unless ($node && $Request{args}{r1} && $Request{args}{r2}) {
        $Request{status} = 404;
        return;
    }

    my %versions;
    for my $r (qw(r1 r2)) {
        my %v = $wiki->retrieve_node(name => Act::Wiki::make_node_name($node), version => $Request{args}{$r});

        unless ($v{version} == $Request{args}{$r}) {
            $Request{status} = 404;
            return;
        }

        $v{user} = Act::User->new(user_id => $v{metadata}{user_id}[0]);
        $v{last_modified} = DateTime::Format::Pg->parse_datetime($v{last_modified});
        $v{content} =~ s/\n?$/\n/s;
        $versions{$r} = \%v;
    }

    my $diff = Text::Diff::diff(
        \$versions{r1}{content},
        \$versions{r2}{content},
        {
            FILENAME_A  => "$node v$Request{args}{r1}",
            FILENAME_B  => "$node v$Request{args}{r2}",
            FILENAME_PREFIX_A => "---",
            FILENAME_PREFIX_B => "+++",
        }
    );

    $template->variables(
        node      => $node,
        r1        => $Request{args}{r1},
        r2        => $Request{args}{r2},
        versions  => \%versions,
        diff      => $diff,
    );

    $template->process('wiki/diff');
}

sub wiki_help
{
    my ($wiki, $template) = @_;
    $template->process('wiki/help');
}

sub wiki_tags
{
    my ($wiki, $template, $tag) = @_;

    # searching by tag
    if ($tag) {
        $tag = Act::Util::normalize($tag);
        my @names = Act::Tag->find_tagged(
            conf_id     => $Request{conference},
            type        => 'wiki',
            tags        => [ $tag ],
        );
        my @nodes;
        for my $node (@names) {
            my $name = Act::Wiki::make_node_name($node);
            my %node = $wiki->retrieve_node(name => $name);
            $node{user} = Act::User->new( user_id => $node{metadata}{user_id}[0]);
            $node{name} = $node;
            $node{last_modified} = DateTime::Format::Pg->parse_datetime($node{last_modified});
            push @nodes, \%node;
        }
        $template->variables(
            nodes  => \@nodes,
        );
    }

    # get tag cloud
    $template->variables_raw(
        tagcloud => Act::Tag->get_cloud(
                        conf_id => $Request{conference},
                        type    => 'wiki',
                    )
    );
    $template->variables(
        tag     => $tag,
    );
    $template->process('wiki/tags');
}

1;

__END__

=head1 NAME

Act::Handler::Wiki - display wiki pages

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
