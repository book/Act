package Act::Handler::User::Main;

use Act::Config;
use Act::Template::HTML;
use Act::User;

sub handler {

    # process the template
    my $template = Act::Template::HTML->new();
#    $template->variables(
#    );
    $template->process('user/main');
}

1;
__END__

=head1 NAME

Act::Handler::User::Main - user's main page

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
