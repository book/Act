package Act::Handler::User::Show;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Country;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    # retrieve user
    my $user;
    # the logged in user is narcissistic
    if ( $Request{user} && $Request{user}->user_id == $Request{path_info} ) {
        # because of the cached $Request{user}, we must load a new user
        $user = Act::User->new( user_id => $Request{path_info} );
    }
    else {
        # "other" user
        $user = Act::User->new(
            user_id => $Request{path_info},
            $Request{conference} ? ( conf_id => $Request{conference} ) : (),
          )
          or do {
            $Request{status} = NOT_FOUND;
            warn "unknown user: $Request{path_info}";
            return;
          };
    }

    # process the template
    my $template = Act::Template::HTML->new();
    my $bio = $user->bio;
    exists $Config->languages->{$_} || delete $bio->{$_} for keys %$bio;

    $template->variables(
        %$user,
        country  => Act::Country::CountryName( $user->country ),
        civility =>
          Act::Util::get_translation( users => civility => $user->civility ),
        talks => [
            grep { $_->accepted
                  || $Request{user}
                  && ( $Request{user}->is_orga
                    || $Request{user}->user_id == $_->user_id )
              } @{ $user->talks(
                      $Request{conference}
                      ? ( conf_id => $Request{conference} ) : ()
                   )
                 },
        ],
        bio => $bio,
    );
    $template->process('user/show');
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
