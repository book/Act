package Act::Request;

use strict;
use warnings;
use parent 'Plack::Request';

sub act_user {
    my ( $self ) = @_;
}

1;

__END__

=head1 NAME

Act::Request - A subclass of Plack::Request that handles like Apache::Request

=head1 DESCRIPTION

=cut
