package Act::User;
use Act::Config;
use Act::Talk;

=head1 NAME

Act::User - A user object

=head1 SYNOPSIS

    $user = Act::User->new();

    # check the user's rights
    $ok = $user->rights()->{orga};
    $ok = $user->is_orga();    # same as above
    

=head1 DESCRIPTION

=head2 Methods

The Act::User class implements the following methods:

=over 4

=item new( $login )

The constructor returns a new Act::User object, given either a login
name. If no user by this name exists, return C<undef>.

=cut

sub new {
    my ( $class, %args ) = @_;

    # can only create users based on login or id
    /^(?:login|id|sid)$/ or delete $args{$_} for keys %args;

    return unless %args;

    my $users = Act::User->get_users( %args );
    return undef if @$users != 1;

    $users->[0];
}

=item rights()

Returns a hash reference which keys are the rights awarded to the
user. Lazy loading is used to fetch the data from the database only
if necessary. The data is then cached for the duration of the request.

=cut

sub rights {
    my $self = shift;
    return $self->{rights} if exists $self->{rights};
    
    # get the user's rights
    $self->{rights} = {};

    $sth = $Request{dbh}->prepare_cached('SELECT right_id FROM rights WHERE conf_id=? AND user_id=?');
    $sth->execute($Request{conference}, $self->{user_id});
    $self->{rights}{$_->[0]}++ for @{ $sth->fetchall_arrayref };
    $sth->finish;

    return $self->{rights};
}

=item is_I<right>()

Returns a boolean value indicating if the current user has the corresponding
I<right>. These convenience methods are autoloaded.

=item accessors

All the accessors give read access to the data held in the users table.
The accessors are autoloaded.

=cut

sub AUTOLOAD {
    # don't DESTROY
    return if $AUTOLOAD =~ /::DESTROY/;

    # methods is_something regard the user rights
    if( $AUTOLOAD =~ /::is_(\w+)$/ ) {
        my $attr = $1;
        if ( $attr eq lc $attr ) {
            no strict 'refs';
    
            # create the method and call it
            *{$AUTOLOAD} = sub { $_[0]->rights()->{$attr} };
            goto &{$AUTOLOAD};
        }
    }
    # get the user attributes
    if( $AUTOLOAD =~  /::(\w+)$/ and exists $_[0]->{$1} ) {
        my $attr = $1;
        if ( $attr eq lc $attr ) {
            no strict 'refs';
    
            # create the method and call it
            *{$AUTOLOAD} = sub { $_[0]->{$attr} };
            goto &{$AUTOLOAD};
        }
    }

    # should we croak? carp? do something?
}

=item update_language

Update the user's language preferences based on the information
available in the current request.

=cut

sub update_language {
    my $self = shift;

    unless (defined $self->{language}
         && $Request{language} eq $self->{language})
    {   
        my $sth = $Request{dbh}->prepare_cached('UPDATE users SET language=? WHERE login=?');
        $sth->execute($Request{language}, $self->{login});
        $Request{dbh}->commit;
        $self->{language} = $Request{language};
    }
}

=item update_sid( $sid )

Update the user's session id. Used internally by Act::Auth.

=cut

sub update_sid {
    my ( $self, $sid ) =@_;
    
    # store the session in the users table
    $sth = $Request{dbh}->prepare_cached('UPDATE users SET session_id=? WHERE login=?');
    $sth->execute($sid, $self->{login});
    $Request{dbh}->commit;

    $self->{session_id} = $sid;
}

=back

=head2 Class methods

Act::User also defines the following class methods:

=over 4

=item get_users( %req )

Return a reference to an array of Act::User objects matching the request
parameters.

    $users = Act::User->get_users( country => 'fr' );

Acceptable parameter are: C<conf>, C<country>, C<town>, C<name> and
C<pm_group>. The C<limit> and C<offset> options can be given to limit
the number of results. All other parameters are ignored.

C<name> does a combined search on the nickname and (if the user does
not want to stay pseudonymous) first name and last name.

=cut

sub get_users {
    my ( $class, %args ) = @_;
    $class = ref $class  || $class;

    # search field to SQL mapping
    my %req = (
        id       => "(u.user_id=?)",
        sid      => "(u.session_id=?)",
        login    => "(u.login=?)",
        conf     => "(p.conf_id=? AND p.user_id=u.user_id)",
        country  => "(u.country=?)",
        town     => "(u.town~*?)",
        name     => "(u.nick_name~*? OR (u.pseudonymous=FALSE AND (u.first_name~*? OR last_name~*?)))",
        pm_group => "(u.pm_group~*?)",
    );

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

    # special cases
    $args{name} = [ ( $args{name} ) x 3 ] if exists $args{name};

    # build the request string
    my $SQL = "SELECT DISTINCT u.* FROM users u, participations p WHERE ";
    $SQL .= join " AND ", "TRUE", @req{keys %args};
    $SQL .= join " ", "", map { $opt{$_} ne '' ? ( uc, $opt{$_} ) : () }
                          keys %opt;

    # run the request
    my $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute( map { (ref) ? @$_ : $_ } values %args );

    my ($users, $user) = [ ];
    push @$users, bless $user, $class while $user = $sth->fetchrow_hashref();

    $sth->finish();

    return $users;
}

=item talks( %req )

Return a reference to an array holding the user's talks that match
the request criterion.

=cut

sub talks {
    my ($self, %args) = @_;
    return Act::Talk->get_talks( %args, user => $self->user_id );
}

1;

