package Act::Handler::User::Search;

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Country;

sub handler {

    # search the users
    my $offset = $Request{args}{prev}
               ? $Request{args}{oprev}
               : $Request{args}{next}
               ? $Request{args}{onext}
               : undef;
    my $limit = $Config->general_searchlimit;
    my $users = %{$Request{args}}
              ? Act::User->get_users( %{$Request{args}},
                  limit => $limit + 1, offset => $offset  )
              : [];

    # offsets for potential previous/next pages
    my ($oprev, $onext);
    $oprev = $offset - $limit if $offset;
    if (@$users > $limit) {
       pop @$users;
       $onext = $offset + $limit;
    }

    # process the search template
    my $template = Act::Template::HTML->new();
    $template->variables(
        countries_iso => \%Act::Country::CountryName,
        countries     => Act::Country::CountryNames(),
        users         => $users,
        oprev         => $oprev,
        prev          => defined($oprev),   # $oprev can be zero
        onext         => $onext,
        next          => defined($onext), 
    );
    $template->process('user/search_form');

}

1;

