package Act::Handler::User::Search;

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Country;

sub handler {

    # process the search template
    my $template = Act::Template::HTML->new();
    $template->variables(
        countries_iso => \%Act::Country::Countries_by_iso,
        countries => Act::Country::CountryNames($Request{language}),
        users => %{$Request{args}}
               ? Act::User->get_users( %{$Request{args}} ) : [],
    );
    $template->process('user/search_form');
}

1;

