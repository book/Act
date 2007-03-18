package Act::Template::Parser;

use strict;
use base qw(Template::Multilingual::Parser);

sub new
{
    my ($class, $options) = @_;
    my $self = $class->SUPER::new($options);

    my $style = $self->{ STYLE }->[-1];
    @$self{ qw(_start _end) } = @$style{ qw( START_TAG END_TAG  ) };
    for (qw( _start _end )) {
        $self->{$_} =~ s/\\([^\\])/$1/g;
    }
    return $self;
}

sub parse
{
    my ($self, $text) = @_;

    # {{string}} => [% "string" | loc %]
    $text =~ s/\{\{\s*(.*?)\s*\}\}/$self->{_start} "$1" | loc $self->{_end}/g;
    return $self->SUPER::parse($text);
}
1;

=head1 NAME

Act::Template::Parser - Template parser

=head1 SYNOPSIS

Only used by Act::Template. Run along now.

=head1 DESCRIPTION

This subclass of Template Toolkit's C<Template::Parser> parses multilingual
templates: templates that contain text in several languages.

    <t>
      <en>Hello!</en>
      <fr>Bonjour !</fr>
    </t>

It also translates strings from .po files using the Act::I18N framework.

    {{ string }}

=cut

1;
