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
    elsif (ref $_[0]) {
        die "unsupported reference: " . ref $_[0];
    }
    elsif (defined $_[0]) {
        $_[0] = HTML::Entities::encode($_[0], '<>&"');
    }
}

sub variables_raw
{
    my $self = shift;
    {
        local *encode = sub { $_[1] };
        $self->SUPER::variables(@_);
    }
}

1;

__END__
