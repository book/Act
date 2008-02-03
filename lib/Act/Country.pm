package Act::Country;
use strict;
use Act::Config;
use Act::I18N;
use Act::Util;

# http://www.iso.org/iso/en/prods-services/iso3166ma/02iso-3166-code-lists/list-en1-semic.txt
my @COUNTRY_CODES = qw(
  ad ae af ag ai al am an ao aq ar as at au aw ax az
  ba bb bd be bf bg bh bi bj bm bn bo br bs bt bv bw by bz
  ca cc cd cf cg ch ci ck cl cm cn co cr cu cv cx cy cz
  de dj dk dm do dz
  ec ee eg eh er es et
  fi fj fk fm fo fr
  ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy
  hk hm hn hr ht hu
  id ie il im in io iq ir is it
  je jm jo jp
  ke kg kh ki km kn kp kr kw ky kz
  la lb lc li lk lr ls lt lu lv ly
  ma mc md me mg mh mk ml mm mn mo mp mq mr ms mt mu mv mw mx my mz
  na nc ne nf ng ni nl no np nr nu nz
  om
  pa pe pf pg ph pk pl pm pn pr ps pt pw py
  qa
  re ro rs ru rw
  sa sb sc sd se sg sh si sj sk sl sm sn so sr st sv sy sz
  tc td tf tg th tj tk tl tm tn to tr tt tv tw tz
  ua ug um us uy uz
  va vc ve vg vi vn vu
  wf ws
  ye yt
  za zm zw
);

my %Cache;

sub CountryNames
{
    my $lh = Act::I18N->get_handle($Request{language});
    return $Cache{$Request{language}} ||=
     [
      Act::Util::usort { $_->{name} }
      map {{ iso => $_, name => $lh->maketext("country_$_") }}
      @COUNTRY_CODES
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
