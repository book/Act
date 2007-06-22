package Act::Handler::User::Search;

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Country;
use Act::Util;

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
                  $Request{conference} ? ( conf_id => $Request{conference} ) : (),
                  limit => $limit + 1, offset => $offset  )
              : [];

    # offsets for potential previous/next pages
    my ($oprev, $onext);
    $oprev = $offset - $limit if $offset;
    if (@$users > $limit) {
       pop @$users;
       $onext = $offset + $limit;
    }

    my ($SQL, $sth, %seen);

    # fetch the countries
    my $countries = Act::Country::CountryNames();
    $SQL = 'SELECT DISTINCT u.country FROM users u, participations p'
         . ' WHERE u.user_id=p.user_id AND p.conf_id=? ORDER BY u.country';
    $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute( $Request{conference} );
    %seen = ( map { $_->[0] => 1 } @{$sth->fetchall_arrayref()} );
    $countries = [ grep { $seen{$_->{iso} } } @$countries ];
    my %by_iso = map { $_->{iso} => $_->{name} } @$countries;

    # fetch the monger groups
    $SQL = 'SELECT DISTINCT u.pm_group FROM users u, participations p'
         . ' WHERE u.user_id=p.user_id AND p.conf_id=? AND u.pm_group IS NOT NULL';
    $sth = $Request{dbh}->prepare_cached( $SQL );
    $sth->execute( $Request{conference} );
    %seen = ();
    $pm_groups = [ Act::Util::usort { $_ }
                   grep !$seen{lc $_}++,
                   map { split /\s*[^\w. -]\s*/, $_->[0] }
                   @{$sth->fetchall_arrayref()}
                 ];
    $sth->finish;

    # process the search template
    my $template = Act::Template::HTML->new();
    $template->variables(
        pm_groups     => $pm_groups,
        countries_iso => \%by_iso,
        countries     => $countries,
        users         => $users,
        oprev         => $oprev,
        prev          => defined($oprev),   # $oprev can be zero
        onext         => $onext,
        next          => defined($onext), 
    );
    $template->process('user/search_form');

}

1;

=head1 NAME

Act::Handler::User::Search - search for users

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
