package Act::Handler::User::Main;

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

    # this guy's participations
    my @parts;
    for my $p (@{$Request{user}->participations}) {
        next if $p->{conf_id} eq $Request{conference};
        my $cfg = Act::Config::get_config($p->{conf_id});
        push @parts, {
            url  => '/' . $cfg->uri . '/',
            name => $cfg->name->{$Request{language}},
        };
    } 
    $template->variables(
        talks => $talks,
        participations => \@parts,
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
