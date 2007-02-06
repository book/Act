package Act::Wiki::Store;

use strict;
use base qw(Wiki::Toolkit::Store::Pg);

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    # work around Wiki::Toolkit::Store::Database 0.27 bug
    $self->{_charset} = 'ISO-8859-1';

    return $self;
}

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
