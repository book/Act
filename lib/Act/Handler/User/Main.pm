package Act::Handler::User::Main;

use strict;
use Act::Config;
use Act::Template::HTML;

sub handler {

    # process the template
    my $template = Act::Template::HTML->new();

    # get this guy's talks
    my %t = ( conf_id => $Request{conference} );
    $t{accepted} = 1 unless $Config->talks_submissions_open
                         or $Request{user}->is_orga;
    my $talks = $Request{user}->talks(%t);

    # all the Act conferences
    my %confs;
    for my $conf_id (keys %{ $Config->conferences }) {
        next if $conf_id eq $Request{conference};
        my $cfg = Act::Config::get_config($conf_id);
        $confs{$conf_id} = {
            conf_id => $conf_id,
            url     => '/' . $cfg->uri . '/',
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
               @{$Request{user}->participations} )
    {
        my $c = $confs{$conf->{conf_id}};
        my $p = \$c->{participation};
        if( $c->{end} < $now )       { $$p = 'past'; }
        elsif ( $c->{begin} > $now ) { $$p = 'future'; }
        else                         { $$p = 'now'; }
    }
    # this guy's payment info
    if ($Request{user}->has_registered() && $Request{user}->has_paid()) {
        $template->variables(
            order => Act::Order->new(
                        user_id => $Request{user}->user_id(),
                        conf_id => $Request{conference},
                        status  => 'paid',
                     ),
        );
    }
    $template->variables(
        talks => $talks,
        conferences => [ sort { $b->{start} cmp $a->{start} } values %confs ],
        can_unregister =>  $Request{user}->has_registered()
                       && !$Request{user}->has_paid()
                       && !$Request{user}->has_talk(),
    );
    $template->process('user/main');
}

1;
__END__

=head1 NAME

Act::Handler::User::Main - user's main page

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
