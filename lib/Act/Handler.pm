package Act::Handler;
use strict;
use warnings;

use parent 'Plack::Component';

sub call {
    my $self = shift;
    my $handler = $self->can('handler');
    $handler->(@_);
}

1;
__END__

=head1 NAME

Act::Handler - parent class for Act handlers

=cut

