package Act::Wiki::Store;

use strict;
use base qw(Wiki::Toolkit::Store::Pg);

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

sub _get_dbh_connect_attr {
    my ($self) = @_;

    return {
        %{ $self->SUPER::_get_dbh_connect_attr() },
        pg_enable_utf8 => 0,
    };
}

1;
