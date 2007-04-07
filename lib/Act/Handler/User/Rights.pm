package Act::Handler::User::Rights;
use strict;
use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Util;
use List::Util qw( sum );

sub handler
{
    # this is for admins only
    unless ($Request{user}->is_admin) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # FIXME fixed list of rights
    my %rights = ( map { ( $_ => 1 ) } qw( orga treasurer admin ) );

    # retrieve all existing rights
    my $sth = $Request{dbh}->prepare_cached(
        'SELECT right_id, user_id FROM rights WHERE conf_id=? ORDER BY right_id, user_id');
    $sth->execute($Request{conference});
    my $rights = $sth->fetchall_arrayref({});

    # associated user info
    $_->{user} = Act::User->new(user_id => $_->{user_id}) for @$rights;

    # rights by user
    my %right;
    for my $r (@$rights) {
        $right{ $r->{user_id} }{user}                    = $r->{user};
        $right{ $r->{user_id} }{user_id}                 = $r->{user_id};
        $right{ $r->{user_id} }{right}{ $r->{right_id} } = 1;
    }

    # handle form submission
    if ($Request{args}{ok}) {

        # new user with rights
        if( my $new = Act::User->new( user_id => $Request{args}{newuser} ) ) {
            $right{new}{user}    = $new;
            $right{new}{user_id} = $Request{args}{newuser};
            $right{new}{right}   = {};
        }

        # for all existing rights
        for my $right_id (keys %rights) {

            # for all users who already have rights
            for my $user_id ( keys %right ) {
                if( $Request{args}{"$user_id-$right_id"} ) {
                    # only insert if it's new
                    if( ! $right{$user_id}{right}{$right_id} ) {
                        $Request{dbh}->prepare_cached(
                            'INSERT INTO rights (right_id, user_id, conf_id) VALUES (?,?,?)'
                            )
                            ->execute( $right_id, $right{$user_id}{user_id},
                            $Request{conference} );
                        $right{$user_id}{right}{$right_id} = 1;
                    }
                }
                elsif( $user_id ne 'new' ) {
                    $Request{dbh}->prepare_cached(
                        'DELETE FROM rights WHERE right_id=? AND user_id=? AND conf_id=?'
                        )
                        ->execute( $right_id, $user_id,
                        $Request{conference} );
                    $right{$user_id}{right}{$right_id} = 0;
                }
            }
        }
        # reset this user's rights cache, so that
        # any change to her rights are applied immediately
        delete $Request{user}{rights};

        $Request{dbh}->commit;

        # clean up the hash
        sum( values %{ $right{$_}{right} } ) || delete $right{$_}
            for keys %right;

    }

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        rights => \%rights,
        right  => [ sort { lc $a->{user}{last_name} cmp lc $b->{user}{last_name} }
                    values %right ],
        right_list => \@Act::Config::Right_ids,
        users  => [ sort { lc $a->{last_name} cmp lc $b->{last_name} }
                    grep { ! exists $right{$_->user_id} }
                    @{Act::User->get_users( conf_id => $Request{conference} )}
                  ],
    );
    $template->process('user/rights');
}

1;
__END__

=head1 NAME

Act::Handler::User::Rights - manage user rights

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
