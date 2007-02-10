package Act::Country;
use strict;
use Act::Config;
use Act::Util;

sub CountryNames
{
   my $c = Act::Util::get_translations('countries', 'iso');
   return
     [
      sort { $a->{name} cmp $b->{name} }
      map {{ iso => $_, name => $c->{$_} }}
      keys %$c
     ];
}

sub CountryName
{
   my $code = shift;
   return Act::Util::get_translation('countries', 'iso', $code) || $code;
}

sub TopTen
{
    # top 10 countries of registered users
    my $sth = $Request{dbh}->prepare_cached(
        'SELECT u.country FROM users u, PARTICIPATIONS p'
      . ' WHERE u.user_id = p.user_id AND p.conf_id = ?'
      . ' GROUP BY u.country ORDER BY COUNT(u.country) DESC LIMIT 10'
      );
      $sth->execute( $Request{conference} );
      my @topten = map {{ iso  => $_->[0],
                          name => CountryName($_->[0]),
                       }}
                       @{ $sth->fetchall_arrayref([]) };
      $sth->finish;
      return \@topten;
}

1;

__END__

=head1 NAME

Act::Country - get country information

=head1 SYNOPSIS

    use Act::Country;
    my $countries = Act::Country::CountryNames;
    my $topten = Act::Country::TopTen;
    my $country_name = Act::Country::CountryName($iso_code);

=cut
