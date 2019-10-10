package Act::Handler::User::Show;
use strict;
use parent 'Act::Handler';

use Act::Config;
use Act::Country;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    # retrieve user_id
    my $user_id = $Request{path_info};
    unless ($user_id =~ /^\d+$/) {
        $Request{status} = 404;
        return;
    }
    # retrieve user
    my $user;
    # the logged in user is narcissistic
    if ( $Request{user} && $Request{user}->user_id == $user_id ) {
        # because of the cached $Request{user}, we must load a new user
        $user = Act::User->new( user_id => $user_id );
    }
    else {
        # "other" user
        $user = Act::User->new(
            user_id => $user_id,
            $Request{conference} ? ( conf_id => $Request{conference} ) : (),
          )
          or do {
            $Request{status} = 404;
            return;
          };
    }

    # process the template
    my $template = Act::Template::HTML->new();
    my %bio = %{$user->bio};  # deep copy avoid double encoding bug
    ( exists $Config->languages->{$_} && $bio{$_} !~ /^\s*$/ )
    || delete $bio{$_} for keys %bio;

    $template->variables(
        %$user, # for backwards compatibility
        user => $user,
        country  => Act::Country::CountryName( $user->country ),
        talks => [
            grep { $_->accepted
                  || $Request{user}
                  && ( $Request{user}->is_users_admin
                    || $Request{user}->user_id == $_->user_id )
              } @{ $user->talks(
                      $Request{conference}
                      ? ( conf_id => $Request{conference} ) : ()
                   )
                 },
        ],
        bio => \%bio,
        conferences => [ grep { $_->{participation} } @{$user->conferences()} ],
        mytalks => $user->my_talks,
        photo_uri => join ('/', undef, 'userphoto', $user->photo_name),
    );
    $template->process('user/show');
    return;
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
