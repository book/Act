package Act::Handler::Talk::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Talk;

sub handler
{

    # retrieve talks and speaker info
    my $talks = Act::Talk->get_talks(conf_id => $Request{conference});
    $_->{user} = Act::User->new(user_id => $_->user_id) for @$talks;

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        talks => [ sort { lc $a->{user}{last_name} cmp lc $b->{user}{last_name} } @$talks ],
    ); 
    $template->process('talk/list');
}

1;
__END__

=head1 NAME

Act::Handler::User::List - show all talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
