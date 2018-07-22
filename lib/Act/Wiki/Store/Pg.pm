package Act::Wiki::Store::Pg;

use strict;

use vars qw( @ISA $VERSION );

use Act::Wiki::Store::Database;
use Carp qw/carp croak/;

@ISA = qw( Act::Wiki::Store::Database );
$VERSION = 0.07;

=head1 NAME

Wiki::Toolkit::Store::Pg - Postgres storage backend for Wiki::Toolkit

=head1 REQUIRES

Subclasses Wiki::Toolkit::Store::Database.

=head1 SYNOPSIS

See Wiki::Toolkit::Store::Database

=cut

# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname, $dbhost, $dbport) = @_;
    my $dsn = "dbi:Pg:dbname=$dbname";
    $dsn .= ";host=$dbhost" if $dbhost;
    $dsn .= ";port=$dbport" if $dbport;
    return $dsn;
}

=head1 METHODS

=over 4

=item B<check_and_write_node>

  $store->check_and_write_node( node     => $node,
                checksum => $checksum,
                                %other_args );

Locks the node, verifies the checksum, calls
C<write_node_post_locking> with all supplied arguments, unlocks the
node. Returns the version of the updated node on successful writing, 0 if
checksum doesn't match, -1 if the change was not applied, croaks on error.

=back

=cut

sub check_and_write_node {
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};

    my $dbh = $self->{_dbh};
    $dbh->{AutoCommit} = 0;

    my $ok = eval {
        $dbh->do("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE");
        $self->verify_checksum($node, $checksum) or return 0;
        $self->write_node_post_locking( %args );
    };
    if ($@) {
        my $error = $@;
        $dbh->rollback;
        $dbh->{AutoCommit} = 1;
        if ( $error =~ /can't serialize access due to concurrent update/i
            or $error =~ /could not serialize access due to concurrent update/i
           ) {
            return 0;
        } else {
            croak $error;
        }
    } else {
        $dbh->commit;
        $dbh->{AutoCommit} = 1;
        return $ok;
    }
}

sub _get_comparison_sql {
    my ($self, %args) = @_;
    if ( $args{ignore_case} ) {
        return "lower($args{thing1}) = lower($args{thing2})";
    } else {
        return "$args{thing1} = $args{thing2}";
    }
}

sub _get_node_exists_ignore_case_sql {
    return "SELECT name FROM node WHERE lower(name) = lower(?) ";
}

1;
