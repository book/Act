use strict;
package Act::Database;
  
my @SCHEMA_UPDATES = (
#1
  "create table schema (
     current_version integer NOT NULL
   );
   insert into schema values (1);
  ",
#2
  "alter table orders add column price text;
   alter table orders add column type text;
  ",
#3
  "alter table users rename civility to salutation;"
);

# returns ( current database schema version, required version )
sub get_versions
{
    my $dbh = shift;
    my $version;
    eval {
        $version = $dbh->selectrow_array('SELECT current_version FROM schema');
    };
    if ($@) {
        $dbh->rollback;
    }
    $version ||= 0;
    return ( $version, required_version() );
}

sub required_version { scalar @SCHEMA_UPDATES }

sub get_update
{
    return $SCHEMA_UPDATES[ $_[0] - 1 ];
}

1;
__END__

=head1 NAME

Act::Database - database schema change tracking

=head1 SYNOPSIS

    my ($version, $required) = Act::Database::get_versions($dbh);
    my $required = Act::Database::required_version();
    my $statements = Act::Database->get_update($version);

=head1 DESCRIPTION

Act::Database implements tracking of schema changes.
When committing code that requires a database schemas change,
developers should add a new element to C<@SCHEMA_UPDATES>
with the SQL statements required to update the schema from
the previous version.

=over 4

=item get_versions(I<$dbh>)

Returns the current database schema version, and the version expected
by this code.

=item required_version()

Returns the database schema version expected by this code.

=item get_update(I<$version>)

Returns an reference to the array of SQL statements necessary to update
the database from version $version - 1 to version $version.

=back

=cut
