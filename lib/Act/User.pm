package Act::User;
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
    select_opt => {
        has_talk  => sub { exists $_[0]{conf_id} ? [ conf_id => "EXISTS(SELECT 1 FROM talks t WHERE t.user_id=u.user_id AND t.conf_id=?) AS has_talk" ] : () },
        has_paid  => sub { exists $_[0]{conf_id} ? [ conf_id => "EXISTS(SELECT 1 FROM orders o WHERE o.user_id=u.user_id AND o.conf_id=? AND o.status = 'paid') AS has_paid" ] : () },
        committed => sub { exists $_[0]{conf_id} ? [ conf_id => "(EXISTS(SELECT 1 FROM talks t WHERE t.user_id=u.user_id AND t.conf_id=? AND t.accepted IS TRUE) OR EXISTS(SELECT 1 FROM orders o WHERE o.user_id=u.user_id AND o.conf_id=? AND o.status = ?)) AS committed" ] : () },
    },
    from       => "users u",
    from_opt   => [
        sub { exists $_[0]{conf_id} ? "participations p" : () },
    ],
);

our %sql_mapping = (
    conf_id    => "(p.conf_id=? AND u.user_id=p.user_id)",
    name       => "(u.nick_name~*? OR (u.pseudonymous IS FALSE AND (u.first_name~*? OR last_name~*?)))",
    # text search
    map( { ($_, "(u.$_~*?)") }
      qw( town pm_group company address ) ),
    # standard stuff
    map( { ($_, "(u.$_=?)") }
      qw( user_id session_id login email country ) )
);
our %sql_opts = ( 'order by' => 'user_id' );

*get_users = \&Act::Object::get_items;

sub talks {
    my ($self, %args) = @_;
    return Act::Talk->get_talks( %args, user_id => $self->user_id );
}

sub participation {
    my ( $self ) = @_;
    my $sth = $Request{dbh}->prepare_cached( 
        'SELECT * FROM participations p WHERE p.user_id=? AND p.conf_id=?' );
    $sth->execute( $self->user_id, $Request{conference} );
    my $participation = $sth->fetchrow_hashref();
    $sth->finish();
    return $participation;
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

Act::User - A user object for the Act framework

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

A few methods have been added.

=head2 Class methods

Act::User also defines the following class methods:

=over 4

=item get_users( %req )

Same as get_items(), except that C<conf_id> can be used to JOIN the users
on their participation to specific conferences.

=item talks( %req )

Return a reference to an array holding the user's talks that match
the request criterion.

=item participation

Return a hash reference holding the user data related to the current
conference.

=back

=cut

