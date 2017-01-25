package Act::Wiki::Store;

use strict;
use base qw< Wiki::Toolkit::Store::Pg >;


sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    # the old version of Wiki::Toolkit we use isn't aware that DBD::Pg 3.x
    # automatically decode the data, so explicitely turn it off
    $self->{_dbh}->{pg_enable_utf8} = 0;

    return $self
}


sub check_and_write_node {
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};

    my $dbh = $self->{_dbh};

    $self->verify_checksum($node, $checksum)
        or return 0;
    $self->write_node_post_locking( %args );
    return 1;
}

1;
