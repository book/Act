package Act::User;
use Act::Config;
use Act::Object;
use Act::Talk;
use Carp;
use base qw( Act::Object );

# class data used by Act::Object
our $table = 'users';
*get_items = \&get_users; # redefined here

Act::User->init();

=head1 NAME

Act::User - A user object for the Act framework

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

A few methods have been added.

=head2 Methods

=over 4

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
    $sth->execute($Request{conference}, $self->user_id);
    $self->{rights}{$_->[0]}++ for @{ $sth->fetchall_arrayref };
    $sth->finish;

    return $self->{rights};
}

=item is_I<right>()

Returns a boolean value indicating if the current user has the corresponding
I<right>. These convenience methods are autoloaded.

=cut

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
    croak "Unknown method $AUTOLOAD";
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

Same as get_items(), except that C<conf_id> can be used to JOIN the users
on their participation to specific conferences.

=cut

sub get_users {
    my ( $class, %args ) = @_;
    $class = ref $class  || $class;

    # search field to SQL mapping
    my %req = (
        conf_id    => "(p.conf_id=? AND u.user_id=p.user_id)",
        town       => "(u.town~*?)",
        name       => "(u.nick_name~*? OR (u.pseudonymous=FALSE AND (u.first_name~*? OR last_name~*?)))",
        pm_group   => "(u.pm_group~*?)",
        # standard stuff
        map( { ($_, "(u.$_=?)") }
          qw( user_id session_id login country ) )
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
    my $conf_id = $args{conf_id};

    # build the request string
    my $SQL = "SELECT DISTINCT u.* FROM users u"
            . ($conf_id ? ", participations p" : "" )
            . " WHERE ";
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
    return Act::Talk->get_talks( %args, user_id => $self->user_id );
}

1;

