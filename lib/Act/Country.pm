package Act::Country;
use strict;
use Act::Config;
use Act::I18N;

sub CountryNames
{
    my $lh = Act::I18N->get_handle($Request{language});
    my %names;
    my $lexicon = $lh->lexicon();
    while (my ($k, $v) = each %$lexicon) {
        if ($k =~ /^country_(.*)$/) {
            $names{$1} = $v;
        }
    }
    return
     [
      sort { $a->{name} cmp $b->{name} }
      map {{ iso => $_, name => $names{$_} }}
      keys %names
     ];
}

sub CountryName
{
   my $code = shift;
   my $lh = Act::I18N->get_handle($Request{language});
   return $lh->maketext("country_$code") || $code;
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
