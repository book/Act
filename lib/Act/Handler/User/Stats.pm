package Act::Handler::User::Stats;
use Act::Config;
use Act::User;
use Act::Country;

use constant SQL_FMT      => q{
    SELECT %s FROM users u, participations p WHERE u.user_id=p.user_id AND p.conf_id=? %s };
use constant SQL_COMMITED => q{
  (
    EXISTS(SELECT 1 from talks t where t.user_id=u.user_id and t.accepted)
  )
};
#    EXISTS(SELECT 1 from orders o where o.user_id=u.user_id and o.state='paid')
#      OR

my %sql = (
    pm_groups =>
      sprintf( SQL_FMT, 'COUNT(*), LOWER(u.pm_group)',
               'AND u.pm_group IS NOT NULL GROUP BY LOWER(u.pm_group)' ),
    countries =>
      sprintf( SQL_FMT, 'COUNT(*), u.country', 'GROUP BY u.country' ),
    towns => 
      sprintf( SQL_FMT, 'COUNT(*), LOWER(u.town), u.country',
               'AND u.town IS NOT NULL GROUP BY u.country, LOWER(u.town)' ),
    users => sprintf( SQL_FMT, 'COUNT(*)', '' ),
    #committed => sprintf( SQL_FMT, 'COUNT(*)', "AND" . SQL_COMMITTED ),
    #com_countries => sprintf( SQL_FMT, 'COUNT(*), u.country', SQL_COMMITTED . ' GROUP BY u.country') ,
    #com_towns => sprintf( SQL_FMT, 'COUNT(*), LOWER(u.town), country', SQL_COMMITTED . ' AND u.town IS NOT NULL GROUP BY u.country, LOWER(u.town)' ),
    #com_pm_groups => sprintf( SQL_FMT, 'COUNT(*), LOWER(u.pm_group)', 'AND u.pm_group IS NOT NULL AND' . SQL_COMMITTED .  ' GROUP BY LOWER(u.pm_group)',
);

sub handler {
    # store some temporary stuff
    my $temp = {};
    for my $query (keys %sql) {
        my $sth = $Request{dbh}->prepare( $sql{$query} );
        $sth->execute( $Request{conference} );
        $temp->{$query} = $sth->fetchall_arrayref();
        $sth->finish();
    }

    # compute the results the template will show
    my $stats = {};
    my $lang  = $Request{language};

    # easy ones, just a copy (one row, one column)
    $stats->{$_} = $temp->{$_}[0][0] for qw( users committed );

    # temp data for committed users
    #my $committed = {};
    #$committed->{countries}{$_->[1]} = $_->[0]
    #    for @{ $temp->{com_countries} };
    #$committed->{towns}{$_->[2]}{$_->[1]} = $_->[0]
    #    for @{ $temp->{com_towns} };
    #$committed->{pm_groups}{$_->[1]} = $_->[0]
    #    for @{ $temp->{com_pm_groups} };

    # list of monger groups
    $stats->{pm} = [ sort { $b->{count} <=> $a->{count} }
          map {{ name      => ucfirst( $_->[1] ),
                 count     => $_->[0],
                 #committed => $committed->{pm_groups}{ $_->[1] } || 0,
            }} @{ $temp->{pm_groups} } ];
    # list of countries
    $stats->{countries} = [ sort { $b->{count} <=> $a->{count} }
          map {{ name      => Act::Country::CountryName( $_->[1] ),
                 iso       => $_->[1],
                 count     => $_->[0],
                 #committed => $committed->{countries}{$_->[1]} || 0,
              }} @{ $temp->{countries} } ];
    # list of towns by country
    for (@{$temp->{towns}}) {
        my $town = $_->[1];
        $_->[1] =~ s/\b(\w)/uc($1)/eg;
        push @{ $stats->{towns}{$_->[2]} }, {
          name      => $_->[1],
          count     => $_->[0],
          #committed => $committed->{towns}{$_->[2]}{$town} || 0
        };
    }
    for my $country (keys %{ $stats->{towns} } ) {
        $stats->{towns}{$country} =
          [ sort { $b->{count} <=> $a->{count} }
            @{ $stats->{towns}{$country} } ];
    }

    my $template = Act::Template::HTML->new();
    $template->variables( stats => $stats );
    $template->process( 'user/stats' );
}

1;

=head1 NAME

Act::Handler::User::Stats - display user statistics

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
