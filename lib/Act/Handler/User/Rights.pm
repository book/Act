package Act::Handler::User::Rights;
use strict;
use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    # this is for admins only
    unless ($Request{user}->is_admin) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # handle form submission
    if ($Request{args}{ok}) {
        my $commit;
        # delete marked lines
        for my $line (keys %{$Request{args}}) {
            if (my ($user_id, $right_id) = $line =~ /^\s*(\d+)-(.*)\s*$/) {
                my $sth = $Request{dbh}->prepare_cached(
                 'DELETE FROM rights WHERE right_id=? AND user_id=? AND conf_id=?'
                );
                $sth->execute($right_id, $user_id, $Request{conference});
                ++$commit;
            }
        }
        # add a right
        my ($user_id, $right_id) =
           map { s/^\s+//; s/\s$//; $_ }
           @{$Request{args}}{qw(newuser newright)};

        if ($user_id =~ /^\d+/ && $right_id) {
            my $u = Act::User->new(user_id => $user_id);
            my $r = "is_$right_id";
            if ($u && !$u->$r) {
                my $sth = $Request{dbh}->prepare_cached(
                 'INSERT INTO rights (right_id, user_id, conf_id) VALUES (?,?,?)'
                );
                $sth->execute($right_id, $user_id, $Request{conference});
                ++$commit;
            }
        }
        $Request{dbh}->commit if $commit;
    }
    # retrieve all rights
    my $sth = $Request{dbh}->prepare_cached(
        'SELECT right_id, user_id FROM rights WHERE conf_id=? ORDER BY right_id, user_id');
    $sth->execute($Request{conference});
    my $rights = $sth->fetchall_arrayref({});

    # associated user info
    $_->{user} = Act::User->new(user_id => $_->{user_id}) for @$rights;

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        rights => $rights,
        users  => [ sort { lc $a->{last_name} cmp lc $b->{last_name} }
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
