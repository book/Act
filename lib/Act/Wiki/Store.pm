package Act::Wiki::Store;

use strict;
use base qw(Act::Wiki::Store::Pg);

sub check_and_write_node
{
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};

    my $dbh = $self->{_dbh};

    $self->verify_checksum($node, $checksum)
        or return 0;
    $self->write_node_post_locking( %args );
    return 1;
}
1;
