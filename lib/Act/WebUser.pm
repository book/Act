package Act::WebUser;
use Act::Config;
use Act::Object;
use Act::Talk;
use Carp;
use base qw( Act::Object );

# class data used by Act::Object
our $table = 'users';
our $primary_key = 'user_id';

our %sql_stub    = (
    select     => "u.*",
    from       => "users u",
);

our %sql_mapping = (
    # standard stuff
    map( { ($_, "(u.$_=?)") }
      qw( user_id session_id login ) )
);

*get_users = \&Act::Object::get_items;

sub rights {
    my $self = shift;
    return $self->{rights} if exists $self->{rights};
    
    # get the user's rights
    $self->{rights} = {};

    $sth = $Request{dbh}->prepare_cached('SELECT right_id FROM rights WHERE conf_id=? AND user_id=?');
    $sth->execute($Request{conference}, $self->user_id);
    $self->{rights}{$_->[0]}++ for @{ $sth->fetchall_arrayref };
    $sth->finish;

    return $self->{rights};
}

# generate the is_right methods
sub AUTOLOAD {

    # don't DESTROY
    return if $AUTOLOAD =~ /::DESTROY/;

    # methods is_something regard the user rights
    if( $AUTOLOAD =~ /::is_(\w+)$/ ) {
        my $attr = $1;
        no strict 'refs';
    
        # create the method and call it
        *{$AUTOLOAD} = sub { $_[0]->rights()->{$attr} };
        goto &{$AUTOLOAD};
    }
    
    # die on error
    croak "AUTOLOAD: Unknown method $AUTOLOAD";
}

sub create {
    my ($class, %args)  = @_;
    $class = ref $class || $class;
    $class->init();

    my $part = delete $args{participation};
    my $user = $class->SUPER::create(%args);
    if ($user && $part && $Request{conference}) {
        @$part{qw(conf_id user_id)} = ($Request{conference}, $user->{user_id});
        my $SQL = sprintf "INSERT INTO participations (%s) VALUES (%s);",
                          join(",", keys %$part), join(",", ( "?" ) x keys %$part);
        my $sth = $Request{dbh}->prepare_cached($SQL);
        $sth->execute(values %$part);
        $sth->finish();
        $Request{dbh}->commit;
    }
    return $user;
}

sub update {
    my ($self, %args) = @_;
    my $class = ref $self;

    my $part = delete $args{participation};
    $self->SUPER::update(%args);
    if ($part && $Request{conference}) {
        delete $part->{$_} for qw(conf_id user_id);
        my $SQL = sprintf 'UPDATE participations SET %s WHERE conf_id=? AND user_id=?',
                          join(',', map "$_=?", keys %$part);
        my $sth = $Request{dbh}->prepare_cached($SQL);
        $sth->execute(values %$part, $Request{conference}, $self->{user_id});
        $Request{dbh}->commit;
    }
}
1;

__END__
=head1 NAME

Act::WebUser - An authenticated user of the Act framework

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

A few methods have been added.

=head2 Methods

=over 4

=item rights()

Returns a hash reference which keys are the rights awarded to the
user. Lazy loading is used to fetch the data from the database only
if necessary. The data is then cached for the duration of the request.

=item is_I<right>()

Returns a boolean value indicating if the current user has the corresponding
I<right>. These convenience methods are autoloaded.

=back

=head2 Class methods

Act::User also defines the following class methods:

=over 4

=item get_users( %req )

Same as get_items(), except that C<conf_id> can be used to JOIN the users
on their participation to specific conferences.

=back

=cut

