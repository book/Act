package Act::Object;
use strict;
use Act::Config;
use Carp;
use DateTime::Format::Pg;

my %normalize = (
    pg => {
        #  4 => integer
        # 12 => text
        93 => sub { # timestamp without time zone
            my $dt = shift;
            ref $dt eq 'DateTime'
            ? DateTime::Format::Pg->format_timestamp_without_time_zone($dt)
            : $dt;
        },
    },
    perl => {
        93 => sub { # timestamp without time zone
            my $dt = shift;
            ref $dt eq 'DateTime'
            ? $dt
            : DateTime::Format::Pg->parse_timestamp_without_time_zone($dt);
        }
    },
);

sub new {
    my ( $class, %args ) = @_;
    $class->init();

    return bless {}, $class unless %args;

    my $items = $class->get_items( %args );
    return undef if @$items != 1;

    $items->[0];
}

sub create {
    my ($class, %args ) = @_;
    $class = ref $class  || $class;
    $class->init();

    my ($table, $pkey, $seq, $data_type);
    { no strict 'refs';
      $table = ${"${class}::table"};
      $pkey  = ${"${class}::primary_key"};
      $seq   = join '_', $table, $pkey, 'seq';
      exists ${"${class}::fields"}{$_} or delete $args{$_} for keys %args;
      $data_type = \%{"${class}::data_type"};
    }
    # insert the new record
    my $id;
    eval {
        my $SQL = sprintf "INSERT INTO $table (%s) VALUES (%s);",
                          join(",", keys %args), join(",", ( "?" ) x keys %args);
        my $sth = $Request{dbh}->prepare_cached( $SQL );
        _normalize( \%args, 'pg', $data_type );
        $sth->execute( values %args );

        # retrieve inserted row's id
        $sth = $Request{dbh}->prepare_cached("SELECT currval(?)");
        $sth->execute($seq);
        ($id) = $sth->fetchrow_array;
        $sth->finish();
        $Request{dbh}->commit;
    };
    if ($@) {
        $Request{dbh}->rollback;
        die $@;
    }
    return $class->new( $pkey => $id );
}

sub update {
    my ($self, %args) = @_;
    my $class = ref $self;
    my ($table, $pkey, $data_type);
    { no strict 'refs';
      $table = ${"${class}::table"};
      $pkey  = ${"${class}::primary_key"};
      exists ${"${class}::fields"}{$_} or delete $args{$_} for keys %args;
      $data_type = \%{"${class}::data_type"};
    }
    eval {
        my $SQL = "UPDATE $table SET "
                . join(',', map "$_=?", keys %args)
                . " WHERE $pkey=?";
        my $sth = $Request{dbh}->prepare_cached( $SQL );
        _normalize( \%args, 'pg', $data_type );
        $sth->execute(values %args, $self->{$pkey});
        $Request{dbh}->commit;
    };
    if ($@) {
        $Request{dbh}->rollback;
        die $@;
    }
    @$self{keys %args} = values %args;
    $self->_normalize( 'perl' );
}

sub clone {
    my $self = shift;
    return bless { %$self }, ref $self;
}

# type: pg | perl
sub _normalize {
    my ( $self, $type, $data_type ) = @_;
    my $class = ref $self;
    $data_type ||= do { no strict 'refs'; \%{"${class}::data_type"} };
    no strict 'refs';
    no warnings;

    my $normalize = $normalize{$type};
    exists $normalize->{ $data_type->{$_} }
      and defined $self->{$_}
      and $self->{$_} = $normalize->{ $data_type->{$_} }->( $self->{$_} )
      for keys %$self;
}

# FIXME
# must add checking somewhere to prevent deleting a user who has talks
sub delete {
    my $self  = shift;
    my $class = ref $self;
    # $class->init; # probably not needed

    no strict 'refs';
    my $table = ${"${class}::table"};
    my $pkey  = ${"${class}::primary_key"};

    eval {
        my $SQL = "DELETE FROM $table WHERE $pkey=?";
        my $sth = $Request{dbh}->prepare_cached( $SQL );
        $sth->execute( $self->{$pkey});
        $Request{dbh}->commit;
    };
    if ($@) {
        $Request{dbh}->rollback;
        die $@;
    }
}

sub init {
    my $class = shift;
    $class = (ref $class) || $class;

    no strict 'refs';

    # get the standard fields (from the table)
    my $table = ${"${class}::table"};
    my $sth   = $Request{dbh}->prepare("SELECT * from $table limit 0;");
    $sth->execute;
    my $fields = ${"${class}::fields"} = $sth->{NAME};
    $sth->finish;

    # get column info
    for my $f (@$fields) {
        my $sth = $Request{dbh}->column_info(undef, undef, $table, $f);
        $sth->execute;
        ${"${class}::data_type"}{$f} = ${$sth->fetchrow_hashref}{DATA_TYPE};
        $sth->finish;
    }
    
    # fill possibly missing keys
    ${"${class}::sql_stub"}{select_opt} ||= {};
    ${"${class}::sql_stub"}{from_opt}   ||= [];

    # create all the accessors at once
    for my $a (@$fields, keys %{ ${"${class}::sql_stub"}{select_opt} }) {
        *{"${class}::$a"} = sub { $_[0]{$a} }
          unless *{"${class}::$a"}{CODE};
    }
    *{"${class}::fields"} = { map { ($_=> 1) } @$fields };

    # let's disappear ;-)
    *{"${class}::init"} = sub {};
}

sub get_items {
    my ( $class, %args ) = @_;
    $class = ref $class  || $class;
    $class->init;

    no strict 'refs';

    # search field to SQL mapping
    my %req = %{"${class}::sql_mapping"};

    # SQL options that can be passed from a form
    my %opt = (
        offset   => '',
        limit    => '',
    );
    
    # clean up the arguments and options
    exists $args{$_} and $opt{$_} = delete $args{$_} for keys %opt;
    $opt{$_} =~ s/\D+//g for qw( offset limit );
    for( keys %args ) {
        # ignore search attributes we do not know
        delete $args{$_} unless exists $req{$_};
        # remove empty search attributes
        delete $args{$_} unless $args{$_}; # FIXME should be ...unless defined $args{$_}
    }

    # SQL options for the derived class
    %opt = ( %opt, %{"${class}::sql_opts"} );

    # create the big hairy SQL statement
    my @select_opt = map { $_->(\%args) }
                         values %{ ${"${class}::sql_stub"}{select_opt} };

    my $SQL = join ' ',
        # SELECT clause
        'SELECT', join( ', ',
            ${"${class}::sql_stub"}{select},
            map { $_->[1] } @select_opt,
        ),
        # FROM
        'FROM', join( ', ',
            ${"${class}::sql_stub"}{from},
            map ( { $_->(\%args) }
                  @{ ${"${class}::sql_stub"}{from_opt} } )
        ),
        # WHERE clause
        'WHERE', join( ' AND ', 'TRUE', @req{keys %args} ),
        # OPTIONS (option order is important)
        map ( { ($opt{$_} || '') ne '' ? ( uc, $opt{$_} ) : () }
              ( 'order by', qw( limit offset ) ) );

    # run the request
    my $items = [ ];
    eval {
        my $sth = $Request{dbh}->prepare_cached( $SQL );
        $sth->execute(
            map ( { ( $args{$_->[0]} ) x $_->[1] =~ y/?// } @select_opt ),
            map ( { ( $args{$_} ) x ${"${class}::sql_mapping"}{$_} =~ y/?// } keys %args ),
        );

        my $item;
        push @$items, bless $item, $class
          and $item->_normalize( 'perl' )
          while $item = $sth->fetchrow_hashref();

        $sth->finish();
    };
    if ($@) {
        $Request{dbh}->rollback;
        die $@;
    }
    return $items;
}

1;

__END__

=head1 NAME

Act::Object - A base object for Act objects

=head1 SYNOPSIS

  use base 'Act::Object';

=head1 DESCRIPTION

=head2 Methods

The Act::Object class implements the following methods:

=over 4

=item new( %args )

The constructor returns an existing Act::Object object, given 
enough parameters to select a single entry.

Calling new() without parameters returns an empty Act::Object.

If no entry is found, return C<undef>.


=item create( %args )

Create a new entry in the database with the corresponding parameters
set and return a Act::Object corresponding to the newly created object.

FIXME: if %args correspond to several entries in the database,
create() will return undef.

=item accessors

All the accessors give read access to the data held in the entry.
The accessors are automatically named and created after the database
columns.

=back

=head2 Class methods

Act::Object also defines the following class methods:

=over 4

=item get_items( %req )

Return a reference to an array of Act::Object objects matching the request
parameters.

Acceptable parameters depend on the actual Act::Object subclass
(See L<SUBCLASSES>).

The C<limit> and C<offset> options can be given to limit
the number of results. All other parameters are ignored.


=back

These classes can also be called on an object instance.

=head1 SUBCLASSES

Creating a subclass of Act::Object should be quite easy: one must
define several package variables in the subclass.

The list of those variables is:

=over 4

=item $table

The name of the table that holds the data for this kind of object in the
database.

=item $primary_key

The column name of the primary key of the table.

=item %sql_mapping

This hash maps search fields to individual parts of the C<WHERE> clause
of the C<SELECT> statement used internaly by C<get_items()>.

Example:

    our %sql_mapping = (
        user_id => '(u.user_id=?)',
        name    => '(u.first_name LIKE ? OR u.last_name LIKE ?),
    );

In this configuration, C<get_items()> will add the C<(u.user_id=?)>
string to the C<WHERE> clause and bind it to the C<user_id> argument
to C<get_items>.

The second pair show that you can use any name for your parameter. And
also that if the string contains several C<?> caracters, the parameter
value will be bound as many times as necessary.

=item %sql_stub

This hash is used to create the complete SQL statement. It can be as
simple as:

    our %sql_stub = (
        select => "u.*",
        from   => "users u",
    );

In some cases, a specific search will require an additional table.
The C<from_opt> key can be used to add optional tables to the C<FROM>
clause.

C<from_opt> is an array reference that contains code references.
The coderefs are passed a hash reference that lists the named arguments
to C<get_items> and must return a string to be added to the C<FROM>
clause.

    our %sql_stub = (
        select   => "u.*",
        from     => "users u",
        from_opt => [
            sub { exists $_[0]{conf_id} ? "participations p" : () },
        ],
    );

In this example, if C<conf_id> is part of the search parameters, then
the C<participation> table will be added to the C<FROM> clause.

The reason is that C<$sql_mapping{conf_id}> is
C<(p.conf_id=? AND u.user_id=p.user_id)>, which requires to add C<p>
(C<participations>) to the C<FROM> clause.

Finally, some optional columns can be returned by the query. This is
done with the C<select_opt> key.

The C<select_opt> key points to a hash reference, whose keys are
the names of the created fields in the corresponding Act::Object subclass
and whose values are code references, just as for C<from_opt>.

The coderefs still receive a hash reference that lists the named
arguments, but they must now return an array reference holding the name
of the query parameter to bind to the placeholder and the SQL code used
to create the computed column.

    our %sql_stub    = (
        select     => "u.*",
        select_opt => {
            has_talk => sub { exists $_[0]{conf_id} ? [ conf_id => "EXISTS(SELECT 1 FROM talks t WHERE t.user_id=u.user_id AND t.conf_id=?) AS has_talk" ] : () },
            },
        from       => "users u",
        from_opt   => [
            sub { exists $_[0]{conf_id} ? "participations p" : () },
        ],
    );

Please note that it is not possible to do a search based on those
optional columns.

=item %sql_opts

This hash holds some options this class can pass to the C<SELECT> clause
created by C<get_items()>. For the moment, only C<order by> is supported.

Example: 

    our %sql_opts = ( 'order by' => 'user_id ASC' );

=back

Once all these package variables are defined, the subclass inherits
C<new()>, C<create()>, C<update()>, C<get_items()> from Act::Object,
as well as the the accessors (for the column names and optional fields).

See Act::Talk for a simple setup and Act::User for a setup using all
these features.

=cut

