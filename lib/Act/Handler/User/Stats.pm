package Act::Handler::User::Stats;

use strict;
use parent 'Act::Handler';

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

    $stats->{committed} = 0;

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
    $towns->{$_} = [ sort { $b->{count} <=> $a->{count}
                         || $b->{committed} <=> $a->{committed}
                     } values %{ $towns->{$_} } ]
      for keys %$towns;

    # update the stats information
    $stats->{users}     = scalar @$users;
    $stats->{countries} = [ sort { $b->{count}     <=> $a->{count}
                                || $b->{committed} <=> $a->{committed}
                            } values %$countries ];
    $stats->{towns} = $towns;
    $stats->{pm}    = [ sort { $b->{count} <=> $a->{count}
                            || $b->{committed} <=> $a->{committed}
                        } values %$pm ];

    my $template = Act::Template::HTML->new();
    $template->variables( stats => $stats );
    $template->process('user/stats');
    return;
}

1;

=head1 NAME

Act::Handler::User::Stats - display user statistics

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut

