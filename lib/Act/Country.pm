package Act::Country;
use strict;
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

1;

__END__

=head1 NAME

Act::Country - get country information

=head1 SYNOPSIS

    use Act::Country;
    my $countries = Act::Country::CountryNames;
    my $country_name = Act::Country::CountryName($iso_code);

=cut
