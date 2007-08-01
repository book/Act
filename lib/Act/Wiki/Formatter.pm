package Act::Wiki::Formatter;
use strict;
use base qw(Wiki::Toolkit::Formatter::Default);

use Act::Abstract;

use HTML::Entities ();
use Text::WikiFormat;
use URI;
use URI::Escape ();

sub _init
{
    my ($self, %args) = @_;

    my %defs = ( extended_links  => 1,
                 implicit_links  => 1,
                 node_prefix     => 'wiki?node=',
               );

    my %collated = (%defs, %args);
    foreach my $k (keys %defs) {
        $self->{"_".$k} = $collated{$k};
    }
    return $self;
}
sub format
{
    my ($self, $raw, $wiki, $metadata) = @_;

    my $cooked = HTML::Entities::encode($raw, '<>&"');

    $self->{chunks} = [];
    my $formatted = Text::WikiFormat::format(
                $cooked,
                {
                  link => sub { _make_link($self, @_) },
                },
                { extended       => $self->{_extended_links},
                  prefix         => $self->{_node_prefix},
                  implicit_links => $self->{_implicit_links},
                }
    );
    $metadata->{chunks} = $self->{chunks}
        if @{ $self->{chunks} };
    return $formatted;
}
sub new_chunk
{
    my ($self, $chunks) = @_;
    push @{ $self->{chunks} }, $chunks;
    return $#{ $self->{chunks} };
}
sub _make_link
{
    my ($formatter, $rawlink, $opts) = @_;
    my ($link, $title) = Text::WikiFormat::find_link_title($rawlink, $opts);
    my $u = URI->new($link);
    my $scheme = $u->scheme();

    my $prefix = '';
    if ($u->scheme) {
        if ($u->scheme eq 'talk') {
            my ($talk, $user) = Act::Abstract::expand_talk(URI::Escape::uri_unescape($u->opaque));
            if ($talk) {
                my $n = $formatter->new_chunk({ talk => $talk, user => $user });
                return "{% expand_talk(chunks.$n) -%}\n";
            }
            return $link;
        }
        elsif ($u->scheme eq 'user') {
            my $user = Act::Abstract::expand_user(URI::Escape::uri_unescape($u->opaque));
            if ($user) {
                my $n = $formatter->new_chunk({ user => $user });
                return "{% expand_user(chunks.$n) -%}\n";
            }
            return $link;
        }
    }
    else {
        $link = URI::Escape::uri_escape_utf8($link);
        $prefix = $opts->{prefix} if defined $opts->{prefix}
    }
    return qq|<a href="$prefix$link">$title</a>|;
}


1;
__END__

=head1 NAME

Act::Wiki::Formatter - A formatter for the wiki.

=head1 DESCRIPTION

A formatter backend for L<Wiki::Toolkit>. Extends L<Wiki::Toolkit::Formatter::Default>
to implement Act-specific link types:

  [talk:id]


=cut
