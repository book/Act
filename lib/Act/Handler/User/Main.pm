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
        warn "doing $conf_id";
        my $cfg = Act::Config::get_config($conf_id);
        $confs{$conf_id} = {
            conf_id => $conf_id,
            url     => '/' . $cfg->uri . '/',
            name    => $cfg->name->{$Request{language}},
            participation => 0,
        };
    }
    # add this guy's participations
    $confs{$_->{conf_id}}{participation} = 1
      for grep { $_->{conf_id} ne $Request{conference} }
               @{$Request{user}->participations};

    $template->variables(
        talks => $talks,
        conferences => [ values %confs ],
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
