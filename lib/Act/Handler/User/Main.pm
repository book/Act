package Act::Handler::User::Main;

use strict;
use Act::Config;
use Act::Template::HTML;
use Act::Order;

sub handler {

    # process the template
    my $template = Act::Template::HTML->new();

    # get this guy's talks
    my %t = ( conf_id => $Request{conference} );
    $t{accepted} = 1 unless $Config->talks_submissions_open
                         or $Request{user}->is_orga;
    my $talks = $Request{user}->talks(%t);

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
        conferences => $Request{user}->conferences(),
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
