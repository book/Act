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
