use Act::Config;
use Act::Template::HTML;
use Act::User;

sub search {
    my $r = $Request{r};

    # HTTP header
    $r->content_type('text/html; charset=iso-8859-1');
    $r->no_cache(1);
    $r->send_http_header();

    # process the login form template
    my $template = Act::Template::HTML->new();
    $template->variables(
        users => Act::User->get_users( %{$Request{args}} )
    );
    $template->process('user/search_form');
}

1;

