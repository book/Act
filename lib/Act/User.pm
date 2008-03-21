package Act::User;
use Act::Config;
use Act::Object;
use Act::Talk;
use Act::Country;
use Act::Util;
use Carp;
use List::Util qw(first);
use base qw( Act::Object );

# class data used by Act::Object
our $table = 'users';
our $primary_key = 'user_id';

our %sql_stub    = (
    select     => "u.*",
    select_opt => {
        committed => sub { exists $_[0]{conf_id} ? [ conf_id => "(EXISTS(SELECT 1 FROM talks t WHERE t.user_id=u.user_id AND t.conf_id=? AND t.accepted IS TRUE) OR EXISTS(SELECT 1 FROM orders o WHERE o.user_id=u.user_id AND o.conf_id=? AND o.status = 'paid') OR EXISTS(SELECT 1 FROM rights r WHERE r.user_id=u.user_id AND r.conf_id=? AND r.right_id IN ('orga','staff'))) AS committed" ] : () },
    },
    from       => "users u",
    from_opt   => [
        sub { exists $_[0]{conf_id} ? "participations p" : () },
    ],
);

our %sql_mapping = (
    conf_id    => "(p.conf_id=? AND u.user_id=p.user_id)",
    name       => "(u.nick_name~*? OR (u.pseudonymous IS FALSE AND (u.first_name~*? OR u.last_name~*? OR (u.first_name || ' ' || u.last_name)~*?)))",
    full_name  =>  "(u.first_name || ' ' || u.last_name ~* ?)",
    # text search
    map( { ($_, "(u.$_~*?)") }
      qw( town company address nick_name ) ),
    # text egality
    map( { ($_, "(lower(u.$_)=lower(?))") }
      qw( first_name last_name pm_group ) ),
    # standard stuff
    map( { ($_, "(u.$_=?)") }
      qw( user_id session_id login email country ) )
);
our %sql_opts = ( 'order by' => 'user_id' );

*get_users = \&get_items;

sub get_items {
    my ($class, %args) = @_;
    
    if( $args{name} ) {
        $args{name} = Act::Util::search_expression( quotemeta( $args{name} ) );
        $args{name} =~ s/\\\*/.*/g;
    }

    return Act::Object::get_items( $class, %args );
}

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

# This are pseudo fields!
sub full_name {
    ( $_[0]->first_name || '' ) . ' ' . ( $_[0]->last_name || '' );
}
sub country_name { Act::Country::CountryName( $_[0]->country ) }


sub bio {
    my $self = shift;
    return $self->{bio} if exists $self->{bio};

    # fill the cache if necessary
    my $sth = $Request{dbh}->prepare_cached(
        "SELECT lang, bio FROM bios WHERE user_id=?"
    );
    $sth->execute( $self->user_id );
    $self->{bio} = {};
    while( my $bio = $sth->fetchrow_arrayref() ) {
        $self->{bio}{$bio->[0]} = $bio->[1];
    }
    $sth->finish();
    return $self->{bio};
}

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

# some data related to the visited conference (if any)
# the information must always be expected as user_id, conf_id
my %methods = (
    has_talk =>
        "SELECT count(*) FROM talks t WHERE t.user_id=? AND t.conf_id=?",
    has_accepted_talk =>
        "SELECT count(*) FROM talks t WHERE t.user_id=? AND t.conf_id=? AND t.accepted",
    has_paid  => 
        "SELECT count(*) FROM orders o WHERE o.user_id=? AND o.conf_id=? AND o.status = 'paid'",
    has_registered => 
        'SELECT count(*) FROM participations p WHERE p.user_id=? AND p.conf_id=?',
);

for my $meth (keys %methods) {
    *{$meth} = sub {
        # compute the data
        my $sth = $Request{dbh}->prepare_cached( $methods{$meth} );
        $sth->execute( $_[0]->user_id, $Request{conference} );
        my $result = $sth->fetchrow_arrayref()->[0];
        $sth->finish();
        return $result;
    };
}

sub participations {
     my $sth = $Request{dbh}->prepare_cached(
        "SELECT * FROM participations p WHERE p.user_id=?"
     );
     $sth->execute( $_[0]->user_id );
     my $participations = [];
     while( my $p = $sth->fetchrow_hashref() ) {
         push @$participations, $p;
     }
     return $participations;
}

sub conferences {
    my $self = shift;

    # all the Act conferences
    my %confs;
    for my $conf_id (keys %{ $Config->conferences }) {
        next if $conf_id eq $Request{conference};
        my $cfg = Act::Config::get_config($conf_id);
        $confs{$conf_id} = {
            conf_id => $conf_id,
            url     => $cfg->general_full_uri,
            name    => $cfg->name->{$Request{language}},
            begin   => DateTime::Format::Pg->parse_timestamp( $cfg->talks_start_date ),
            end     => DateTime::Format::Pg->parse_timestamp( $cfg->talks_end_date ),
            participation => 0,
            # opened => ?
        };
    }
    # add this guy's participations
    my $now = DateTime->now;
    for my $conf (grep { $_->{conf_id} ne $Request{conference} }
               @{$self->participations()} )
    {
        my $c = $confs{$conf->{conf_id}};
        my $p = \$c->{participation};
        if( $c->{end} < $now )       { $$p = 'past'; }
        elsif ( $c->{begin} > $now ) { $$p = 'future'; }
        else                         { $$p = 'now'; }
    }

    return [ sort { $b->{begin} <=> $a->{begin} } values %confs ]
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
    my $bio  = delete $args{bio};
    $self->SUPER::update(%args) if %args;
    if ($part && $Request{conference}) {
        delete $part->{$_} for qw(conf_id user_id);
        my $SQL = sprintf 'UPDATE participations SET %s WHERE conf_id=? AND user_id=?',
                          join(',', map "$_=?", keys %$part);
        my $sth = $Request{dbh}->prepare_cached($SQL);
        $sth->execute(values %$part, $Request{conference}, $self->{user_id});
        $Request{dbh}->commit;
    }
    if( $bio ) {
        my @sth = map { $Request{dbh}->prepare_cached( $_ ) }
        (
            "SELECT 1 FROM bios WHERE user_id=? AND lang=?",
            "UPDATE bios SET bio=? WHERE user_id=? AND lang=?",
            "INSERT INTO bios ( bio, user_id, lang) VALUES (?, ?, ?)",
        );
        for my $lang ( keys %$bio ) {
            $sth[0]->execute( $self->user_id, $lang );
            if( $sth[0]->fetchrow_arrayref ) {
                $sth[1]->execute( $bio->{$lang}, $self->user_id, $lang );
            }
            else {
                $sth[2]->execute( $bio->{$lang}, $self->user_id, $lang );
            }
            $sth[0]->finish;
            $Request{dbh}->commit;
        }
    }
}

sub possible_duplicates {
    my ($self) = @_;
    my %seen = ( $self->user_id => 1 );
    my @twins;
    
    for my $attr (qw( login email nick_name full_name last_name )) {
        push @twins, grep { !$seen{ $_->user_id }++ }
            map {@$_}
            Act::User->get_items( $attr => map { s/([.*(){}^$?])/\\$1/g; $_ }
                $self->$attr() )
            if $self->$attr();
    }
    $_->most_recent_participation() for @twins;

    @twins = sort { $a->user_id <=> $b->user_id } @twins;

    return \@twins;
}
sub most_recent_participation {
    my ($self) = @_;

    # get all participations
    my $participations = $self->participations;

    # prefer current conference
    my $chosen = first { $_->{conf_id} eq $Request{conference} } @$participations;
    unless ($chosen) {
        # if no participation date, use conference start date instead
        for my $p (@$participations) {
            $p->{datetime} ||= Act::Config::get_config($p->{conf_id})->talks_start_date;
        }
        # sort participations in reverse chronological order
        my @p = sort { $b->{datetime} cmp $a->{datetime} } @$participations;
        
        # choose most recent participation
        $chosen = $p[0];
    }
    # add url information
    $chosen->{url} = Act::Config::get_config($chosen->{conf_id})->general_full_uri
        if $chosen->{conf_id};
    $self->{most_recent_participation} = $chosen;
}

1;

__END__

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

=item talks( %req )

Return a reference to an array holding the user's talks that match
the request criterion.

=item participation

Return a hash reference holding the user data related to the current
conference.

=back

=cut

