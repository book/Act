package Act::Template::HTML;

use strict;
use HTML::Entities;
use base 'Act::Template';

sub encode
{
   # recursively encode HTML entities
    my $self = shift;
    if ($_[0] && UNIVERSAL::isa($_[0],'ARRAY')) {
        $self->encode($_) for @{$_[0]};
    }
    elsif ($_[0] && UNIVERSAL::isa($_[0],'HASH')) {
        $self->encode($_[0]{$_}) for keys %{$_[0]};
    }
    elsif (ref $_[0] eq 'CODE') {
        return;
    }
    elsif (!ref($_[0]) && defined($_[0])) {
        $_[0] = HTML::Entities::encode($_[0], '<>&"');
    }
}

sub variables_raw
{
    my $self = shift;
    {
        no warnings 'redefine';
        local *encode = sub { $_[1] };
        $self->SUPER::variables(@_);
    }
}

1;

__END__

=head1 NAME

Act::Template::HTML - an HTML template object class

=head1 SYNOPSIS

    use Act::Template::HTML;
    my $template = Act::Template::HTML->new();
    $template->variables(foo => 42);
    $template->process('talkview');

=head1 DESCRIPTION

The Act::Template::HTML class is used to process Act templates that contain
HTML text.

=head2 Methods

Act::Template::HTML inherits from Act::Template, and adds or overrides the
following methods:

=over 4

=item variables(I<%variables>)

Set template variables. Does a recursive scan of the variable values
and escapes all HTML characters (&, E<lt> and E<gt> are converted to
HTML entities).

=item variables_raw(I<%variables>)

Set template variables without escaping. This is useful when a variable
value holds an already properly formatted HTML or XML snippet.

=cut
