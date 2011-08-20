package Act::User;
use strict;

use Act::Config;
use Act::Object;
use Act::Talk;
use Act::Country;
use Act::Util;
use Digest::MD5 qw( md5_hex );
use Carp;
use List::Util qw(first);
use base qw( Act::Object );
use Crypt::Eksblowfish::Bcrypt;

# rights
our @Rights = qw( admin users_admin talks_admin news_admin wiki_admin
    staff treasurer );

# class data used by Act::Object
our $table = 'users';
our $primary_key = 'user_id';

our %sql_stub    = (
    select     => "u.*",
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
      qw( first_name last_name) ),
    # user can have multiple entries in pm_group
    pm_group => "position(lower(?) in lower(u.pm_group)) > 0",
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

    my $sth = sql(
                       'SELECT right_id FROM rights WHERE conf_id=? AND user_id=?',
                       $Request{conference}, $self->user_id
                      );
    $self->{rights}{$_->[0]}++ for @{ $sth->fetchall_arrayref };
    $sth->finish;

    return $self->{rights};
}

# generate the is_right methods
for my $right (@Rights) {
    no strict 'refs';
    *{"is_$right"} = sub { $_[0]->rights()->{$right} };
}

# This are pseudo fields!
sub full_name {
    ( $_[0]->first_name || '' ) . ' ' . ( $_[0]->last_name || '' );
}

sub country_name { Act::Country::CountryName( $_[0]->country ) }

sub public_name {
    return $_[0]->pseudonymous ? $_[0]->nick_name
         : $_[0]->first_name." ".$_[0]->last_name;
}


sub bio {
    my $self = shift;
    return $self->{bio} if exists $self->{bio};

    # fill the cache if necessary
    my $sth = sql("SELECT lang, bio FROM bios WHERE user_id=?", $self->user_id );
    $self->{bio} = {};
    while( my $bio = $sth->fetchrow_arrayref() ) {
        $self->{bio}{$bio->[0]} = $bio->[1];
    }
    $sth->finish();
    return $self->{bio};
}

sub md5_email {
    my $self = shift;
    return $self->{md5_email} ||= md5_hex( lc $self->email );
}

sub talks {
    my ($self, %args) = @_;
    return Act::Talk->get_talks( %args, user_id => $self->user_id );
}
sub register_participation {
  my ( $self ) = @_;
  
  my $sth = $Request{dbh}->prepare_cached(q{
        SELECT  tshirt_size
        FROM    participations
        WHERE   user_id = ?
        AND tshirt_size is not null
        ORDER BY datetime DESC
        LIMIT 1
  });
                                
  $sth->execute( $self->user_id );
  my ($tshirt_size) = $sth->fetchrow_array;
  $sth->finish;
                                
  # create a new participation to this conference
  $sth = $Request{dbh}->prepare_cached(q{
        INSERT INTO participations
          (user_id, conf_id, datetime, ip, tshirt_size)
        VALUES  (?,?, NOW(), ?, ?)
  });
  
  $sth->execute( $self->user_id, $Request{conference},
    $Request{r}->connection->remote_ip, $tshirt_size );
  $sth->finish();
  $Request{dbh}->commit;
}
sub participation {
    my ( $self ) = @_;
    my $sth = sql('SELECT * FROM participations p WHERE p.user_id=? AND p.conf_id=?',
                  $self->user_id, $Request{conference} );
    my $participation = $sth->fetchrow_hashref();
    $sth->finish();
    return $participation;
}

sub my_talks {
    my ($self) = @_;
    return $self->{my_talks} if $self->{my_talks};
    my $sth = sql(<<EOF, $self->user_id, $Request{conference} );
SELECT u.talk_id FROM user_talks u, talks t
WHERE u.user_id=? AND u.conf_id=?
AND   u.talk_id = t.talk_id
AND   t.accepted
EOF
    my $talk_ids = $sth->fetchall_arrayref();
    $sth->finish();
    return $self->{my_talks} = [ map Act::Talk->new( talk_id => $_->[0] ), @$talk_ids ];
}

sub update_my_talks {
    my ($self, @talks) = @_;

    my %ids     = map { $_->talk_id => 1 } @talks;
    my %current = map { $_->talk_id => 1 } @{ $self->my_talks };

    # remove talks
    my @remove = grep { !$ids{$_} } keys %current;
    if (@remove) {
        sql(
                    "DELETE FROM user_talks WHERE user_id = ? AND conf_id = ? AND talk_id IN ("
                  .  join(',', map '?',@remove)
                  . ')',
                  $self->user_id, $Request{conference}, @remove
           );
    }
    # add talks
    my @add = grep { !$current{$_} } keys %ids;
    if (@add) {
        my $SQL = "INSERT INTO user_talks VALUES (?,?,?)";
        my $sth = sql_prepare($SQL);
        sql_exec($sth, $SQL, $self->user_id, $Request{conference}, $_)
            for @add;
    }
    $Request{dbh}->commit  if @add || @remove;
    $self->{my_talks} = [ grep $_->accepted, @talks ];
}

sub is_my_talk {
    my ($self, $talk_id) = @_;
    return first { $_->talk_id == $talk_id } @{ $self->my_talks };
}

sub attendees {
    my ($self, $talk_id) = @_;
    my $sth = sql(<<EOF, $talk_id, $Request{conference} );
SELECT user_id FROM user_talks
WHERE talk_id=? AND conf_id=?
EOF
    my $user_ids = $sth->fetchall_arrayref();
    $sth->finish();
    return [ map Act::User->new( user_id => $_->[0] ), @$user_ids ];
}

# some data related to the visited conference (if any)
my %methods = (
    has_talk => [
        "SELECT count(*) FROM talks t WHERE t.user_id=? AND t.conf_id=?",
        sub { ( $_[0]->user_id, $Request{conference} ) },
    ],
    has_accepted_talk => [
        "SELECT count(*) FROM talks t WHERE t.user_id=? AND t.conf_id=? AND t.accepted",
        sub { ( $_[0]->user_id, $Request{conference} ) },
    ],
    has_paid  => [
        "SELECT count(*) FROM orders o, order_items i
            WHERE o.user_id=? AND o.conf_id=?
              AND o.status = ?
              AND o.order_id = i.order_id
              AND i.registration",
        sub { ( $_[0]->user_id, $Request{conference}, 'paid' ) },
    ],
    has_registered => [
        'SELECT count(*) FROM participations p WHERE p.user_id=? AND p.conf_id=?',
        sub { ( $_[0]->user_id, $Request{conference} ) },
    ],
    has_attended => [
        'SELECT count(*) FROM participations p WHERE p.user_id=? AND p.conf_id=? AND p.attended IS TRUE',
        sub { ( $_[0]->user_id, $Request{conference} ) },
    ],
);

for my $meth (keys %methods) {
    no strict 'refs';

    *{$meth} = sub {
        my $self = shift;
        return $self->{$meth} if exists $self->{$meth};
        # compute the data
        my ($sql, $getargs) = @{ $methods{$meth} };
        my $sth = sql( $sql, $getargs->($self) );
        $self->{$meth} = $sth->fetchrow_arrayref()->[0];
        $sth->finish();
        return $self->{$meth};
    };
}
sub committed {
    my $self = shift;
    return $self->has_paid
        || $self->has_attended
        || $self->has_accepted_talk
        || $self->is_staff
        || $self->is_users_admin
        || $self->is_talks_admin
        || $self->is_news_admin
        || $self->is_wiki_admin;
}

sub participations {
     my $sth = sql(
        "SELECT * FROM participations p WHERE p.user_id=?",
         $_[0]->user_id );
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
    my $password = delete $args{password};
    $args{passwd} = $class->_crypt_password($password)
        if defined $password;
    my $user = $class->SUPER::create(%args);
    if ($user && $part && $Request{conference}) {
        @$part{qw(conf_id user_id)} = ($Request{conference}, $user->{user_id});
        my $SQL = sprintf "INSERT INTO participations (%s) VALUES (%s);",
                          join(",", keys %$part), join(",", ( "?" ) x keys %$part);
        my $sth = sql( $SQL, values %$part );
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
        my $sth = sql( $SQL, values %$part, $Request{conference}, $self->{user_id} );
        $Request{dbh}->commit;
    }
    if( $bio ) {
        my @SQL =
        (
            "SELECT 1 FROM bios WHERE user_id=? AND lang=?",
            "UPDATE bios SET bio=? WHERE user_id=? AND lang=?",
            "INSERT INTO bios ( bio, user_id, lang) VALUES (?, ?, ?)",
        );
        my @sth = map sql_prepare($_), @SQL;
        for my $lang ( keys %$bio ) {
            sql_exec( $sth[0], $SQL[0], $self->user_id, $lang );
            if( $sth[0]->fetchrow_arrayref ) {
                sql_exec(  $sth[1], $SQL[1], $bio->{$lang}, $self->user_id, $lang );
            }
            else {
                sql_exec( $sth[2], $SQL[2],  $bio->{$lang}, $self->user_id, $lang );
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

sub set_password {
    my $self = shift;
    my $password = shift;
    my $crypted = $self->_crypt_password($password);
    $Request{user}->update( passwd => $crypted );
    return 1;
}

sub _crypt_password {
    my $class = shift;
    my $pass = shift;
    my $cost = $Config->bcrypt_cost;
    my $salt = $Config->bcrypt_salt;
    return '{BCRYPT}' . Crypt::Eksblowfish::Bcrypt::en_base64(
        Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
            key_nul => 1,
            cost => $cost,
            salt => $salt,
        }, $pass)
    );
}

sub check_password {
    my $self = shift;
    my $check_pass = shift;

    my $pw_hash = $self->{passwd};
    my ($scheme, $hash) = $pw_hash =~ /^(?:{(\w+)})?(.*)$/;
    $scheme ||= 'MD5';

    if ($scheme eq 'MD5') {
        my $digest = Digest::MD5->new;
        $digest->add(lc $check_pass);
        $digest->b64digest eq $self->{passwd}
            or die 'Bad password';
        # upgrade hash
        $self->set_password($check_pass);
    }
    elsif ($scheme eq 'BCRYPT') {
        my $check_hash = $self->_crypt_password($check_pass);
        $check_hash eq $pw_hash
            or die 'Bad password';
    }
    else {
        die 'Bad user data';
    }
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

