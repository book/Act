package Act::Handler::User::Main;

use Act::Config;
use Act::Template::HTML;

sub handler {

    # process the template
    my $template = Act::Template::HTML->new();

    # get this guy's talks
    if ($Config->talks_submissions_open) {
        my %t = ( conf_id => $Request{conference} );
        $t{accepted} = 1 unless $Request{user}->is_orga;
        my $talks = $Request{user}->talks(%t);
        $template->variables(talks => $talks);
    }
    $template->process('user/main');
}

1;
__END__

=head1 NAME

Act::Handler::User::Main - user's main page

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
