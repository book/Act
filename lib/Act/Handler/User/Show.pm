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
    my $user = Act::User->new(user_id => $Request{path_info})
        or do {
            $Request{status} = NOT_FOUND;
            warn "unknown user: $Request{path_info}";
            return;
        };

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        %$user,
        country => Act::Country::CountryName($user->country),
        civility => Act::Util::get_translation( users => civility => $user->civility ),
        talks    => $user->talks,
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
