package Act::Handler::User;

use Act::Config;
use Act::Template::HTML;
use Act::User;

sub search {

    # process the search template
    my $template = Act::Template::HTML->new();
    $template->variables(
        users => %{$Request{args}}
               ? Act::User->get_users( %{$Request{args}} ) : [],
    );
    $template->process('user/search_form');
}

1;

