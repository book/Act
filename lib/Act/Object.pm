package Act::Object;
use strict;
use Act::Config;
use Carp;

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

    my $item = $class->new( %args );
    return undef if $item;

    my $table;
    { no strict 'refs'; $table = ${"${class}::table"}; }
    my $SQL = sprintf "INSERT INTO $table (%s) VALUES (%s);",
                      join(",", keys %args), join(",", ( "?" ) x keys %args);
    my $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute( values %args );
    $sth->finish();
    $Request{dbh}->commit;

    return $class->new( %args );
}

sub update {
    my ($self, %args) = @_;
    my $class = ref $self;
    my ($table, $pkey);
    { no strict 'refs';
      $table = ${"${class}::table"};
      $pkey  = ${"${class}::primary_key"};
      exists ${"${class}::fields"}{$_} or delete $args{$_} for keys %args;
    }
    my $SQL = "UPDATE $table SET "
            . join(',', map "$_=?", keys %args)
            . " WHERE $pkey=?";
    my $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute(values %args, $self->{$pkey});
    $Request{dbh}->commit;
    @$self{keys %args} = values %args;
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

    # fill possibly missing keys
    ${"${class}::sql_stub"}{select_opt} ||= {};
    ${"${class}::sql_stub"}{from_opt}   ||= [];

    # create all the accessors at once
    for my $a (@$fields, keys %{ ${"${class}::sql_stub"}{select_opt} }) {
        *{"${class}::$a"} = sub { $_[0]{$a} };
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

    # SQL options
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
        delete $args{$_} unless $args{$_};
    }

    # SQL options for the derived class
    %opt = ( %opt, %{"{$class}::sql_opts"} );

    # create the big hairy SQL statement
    my $SQL = join ' ',
        # SELECT clause
        'SELECT', join( ', ',
            ${"${class}::sql_stub"}{select},
            map ( { $_->(\%args) }
                  values %{ ${"${class}::sql_stub"}{select_opt} } ),
        ),
        # FROM
        'FROM', join( ', ',
            ${"${class}::sql_stub"}{from},
            map ( { $_->(\%args) }
                  @{ ${"${class}::sql_stub"}{from_opt} } )
        ),
        # WHERE clause
        'WHERE', join( ' AND ', 'TRUE', @req{keys %args} ),
        # OPTIONS
        map ( { $opt{$_} ne '' ? ( uc, $opt{$_} ) : () } keys %opt );

    # run the request
    my $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute(
        map { ( $args{$_} ) x ${"${class}::sql_mapping"}{$_} =~ y/?// }
        keys %args
    );

    my ($items, $item) = [ ];
    push @$items, bless $item, $class while $item = $sth->fetchrow_hashref();

    $sth->finish();

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

Creating a subclass of Act::Object should be quite easy:

    package Act::Foo;
    use Act::Object;
    use base qw( Act::Object );

    # information used by new()
    our $new_args = qr/^(?:foo_id|user_id)$/;

    # information used by create()
    our $table = "foos";     # the table holding object data
    out $primary_key = 'foo_id';  # used by update()

    # information used by get_items()
    our %sql_stub = (
        select => "f.*",
        select_opt => {
            max => sub { exists $_[0]{bar} ? 'max( f.number )' : () }
        },
        from       => "foos f",
        from_opt   => [
            # a list of subroutines that return table names given $args
        ],
    };
    our %sql_opts = ();      # SQL options for get_items()
    our %sql_mapping = (
          bar => "(f.bar1=? OR f.bar=?)",
          # simple stuff
          map ( { ( $_, "(f.$_=?)" ) } qw( foo_id conf_id ) ),
    );

    # Your class now inherits new(), create(), update(), get_items()
    # and the accessors (for the column names and optional fields)

    # Alias the search method
    *get_foos = \&Act::Object::get_items;

    # Create the accessors and helper methods
    Act::Foo->init();

See Act::Talk for a simple setup and Act::User for a setup using all
these features.

=cut
