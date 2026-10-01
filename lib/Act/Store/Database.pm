package Act::Store::Database;
# ABSTRACT: Use relational databases as store for Act data

use 5.020;

use DBIx::Connector;
use Try::Tiny;

use Act::Config (); # Let's stick to that for the moment
                    # but do not use the exports
use Act::Database;  # Actually, that' the schema history
use Act::Schema;    # That's how we intend to do it from now on

use Moo;
use Types::Standard qw(InstanceOf);
with 'MooX::Singleton';

no warnings qw(experimental::signatures);
use feature qw(signatures);

# ======== Class Variables =============================================
my $db_singleton;


# ======== Attributes ==================================================
has connector => (
    is => 'ro', isa => InstanceOf['DBIx::Connector'],
    lazy => 1,
    builder => '_build_connector',
    handles => [ 'dbh' ],
);

has schema => (
    is => 'ro', isa => InstanceOf['Act::Schema'],
    lazy => 1,
    builder => '_build_schema',
);


# -------- Attribute helpers -------------------------------------------
sub _build_connector ($self) {
    my $Config = $Act::Config::Config;
    my $dsn = $Config->database_dsn;
    if ($Config->database_host) {
        $dsn .= ";host=" . $Config->database_host;
    }

    my $connector = DBIx::Connector->new(
        $dsn,
        $Config->database_user,
        $Config->database_passwd,
        { AutoCommit => 1,
          PrintError => 0,
          RaiseError => 1,
          pg_enable_utf8 => 1,
        }
    );
    $connector->mode('fixup');

    return $connector;
}

sub _build_schema ($self) {
    my $dbh = Act::Store::Database->instance->dbh;
    return Act::Schema->connect( sub { $dbh } );
}

=head1 METHODS

=cut


# ======== Singleton definition and helpers ============================

=head2 $db = instance()

Returns the instance of the database store, or dies on failure.

=cut

# BUILD
# After object creation, check whether the versions of code and schema match
sub BUILD ($self,@) {
    $self->_check_db_version;
}

# _check_db_version
#   Purpose: Make sure that the code understands the database schema.
sub _check_db_version ($self) {
    my $current_version = $self->get_schema_version();
    my $required_version = Act::Database::required_version;
    if ($current_version > $required_version) {
        die "database schema version $current_version is too recent: " .
            "this code runs version $required_version\n";
    }
    if ($current_version < $required_version) {
        die "database schema version $current_version is too old: " .
            "version $required_version is required. Run bin/dbupdate\n";
    }
}

# ======== Data Manipulation Methods ===================================

=head2 Database Metadata

=head3 $version = $db->get_schema_version()

Returns the schema version as provided by the database.  Dies if the
version can't be retrieved.

=cut

sub get_schema_version ($self) {
    my $current_version = try {
        $self->connector->run(
            sub {
                $_->selectrow_array('SELECT current_version FROM schema');
            }
        );
    } catch {
        die "Failed to retrieve the schema version:\n",
            "DB error:   '", DBI->errstr, "'\n",
            "eval error: '$_'";
    };
}


# ======================================================================

=head2 Methods for a conference data servoce

The folliowing methods usually pass a conference in their parameter
lists, though some of the tables collect items for all conferences.

# ----------------------------------------------------------------------

=head3 Method user_rights

Returns an array reference to the rights of a C<user_id> for a
C<$conference>.

=cut

sub user_rights ($self,$conference,$user_id) {
    my $sql = 'SELECT right_id FROM rights WHERE conf_id=? AND user_id=?';
    return $self->connector->run(
        sub {
            my $sth = $_->prepare_cached($sql);
            $sth->execute($conference, $user_id);
            my @rights = map { $_->[0] } @{ $sth->fetchall_arrayref };
            $sth->finish;
            return \@rights;
        }
    );
}


1;

__END__

=encoding utf8

=head1 NAME

Act::Store::Database - Use relational databases as store for Act data

=head1 SYNOPSIS

  $db             = Act::Store::Database->instance;
  $schema_version = $db->get_schema_version;

=head1 DESCRIPTION

This class represents the database which stores Act data as a
singleton.  All operations Act needs to perform on a persistent store
are available as method calls against this singleton.

Or, to be precise: They I<will> be available, at some point in the
future.  During the course of refurbishment this singleton will live
happily together with the traditional C<$Request{dbh}> used by legacy
Act software.

=head1 DIAGNOSTICS

In case of error, methods of this class just die.

=head1 ENVIRONMENT

No environment variables are evaluated yet.  Sorry, dockers!

=head1 FILES

The code relies on the C<$Act::Config::Config> object which reads its
database connection parameters from the global F<act.ini> file.

=head1 CAVEATS

This code hasn't been seriously tested in real life and covers only a
tiny part of Act's database actions.

=cut

# =head1 RESTRICTIONS

# =head1 NOTES

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
