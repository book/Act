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
