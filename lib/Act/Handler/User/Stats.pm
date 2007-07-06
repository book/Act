package Act::Handler::User::Stats;
use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Country;

sub handler {

    # temporary variables
    my $users     = Act::User->get_items( conf_id => $Request{conference} );
    my $countries = {};
    my $towns     = {};
    my $pm        = {};
    my $stats     = {};

    for my $u (@$users) {
        my ( $c, $t, $p ) = ( $u->country, $u->town, $u->pm_group );
        $countries->{$c}{count}++ || do {
            $countries->{$c}{name} ||= Act::Country::CountryName($c);
            $countries->{$c}{iso}  ||= $c;
            $countries->{$c}{committed} = 0;
        };
        if ($t) {
            $towns->{$c}{$t}{count}++ || do {
                $towns->{$c}{$t}{name}      = $t;
                $towns->{$c}{$t}{committed} = 0;
            };
        }
        if ($p) {
            for my $g (split(/\s*[^\w. -]\s*/, $p)) {
                my $lg = lc $g;
                $pm->{$lg}{count}++ || do {
                    $pm->{$lg}{name}      = $g;
                    $pm->{$lg}{committed} = 0;
                };
                $pm->{$lg}{committed}++ if $u->committed;
            }
        }

        # commited info
        if ( $u->committed ) {
            $countries->{$c}{committed}++;
            $towns->{$c}{$t}{committed}++ if $t;
            $stats->{committed}++;
        }
    }

    # sort the towns for each country
    $towns->{$_} =
      [ sort { $b->{count} <=> $a->{count} } values %{ $towns->{$_} } ]
      for keys %$towns;

    # update the stats information
    $stats->{users}     = scalar @$users;
    $stats->{countries} =
      [ sort { $b->{count} <=> $a->{count} } values %$countries ];
    $stats->{towns} = $towns;
    $stats->{pm}    = [ sort { $b->{count} <=> $a->{count} } values %$pm ];

    my $template = Act::Template::HTML->new();
    $template->variables( stats => $stats );
    $template->process('user/stats');
}

1;

=head1 NAME

Act::Handler::User::Stats - display user statistics

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut

