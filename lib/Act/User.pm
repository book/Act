package Act::User;
use Act::Config;

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
    my ( $class, $login ) = @_;

    my $sth = $Request{dbh}->prepare_cached('SELECT * FROM users WHERE login=?');
    $sth->execute($login);
    my $self = $sth->fetchrow_hashref();
    $sth->finish;

    return undef unless $self;

    bless $self, $class;
}

=item new_from_sid( $sid )

Return a new user object, corresponding to the given session id.
If no user corresponds to the session id, C<undef> is returned.

=cut

sub new_from_sid {
    my ( $class, $sid ) = @_;

    # search for this user in our database
    my $sth = $Request{dbh}->prepare_cached('SELECT * FROM users WHERE session_id=?');
    $sth->execute($sid);
    $self = $sth->fetchrow_hashref;
    $sth->finish;

    # unknown session id
    return undef unless $self;

    return bless $self, $class;
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
    if( $AUTOLOAD =~  /::(\w+)$/ and exists $self->{$1} ) {
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

=cut

1;

