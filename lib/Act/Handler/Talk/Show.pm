package Act::Handler::Talk::Show;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Talk;

sub handler
{
    # available only if submissions open or organizer
    unless ($Config->talks_submissions_open
            || ($Request{user} && $Request{user}->is_orga))
    {
        $Request{status} = NOT_FOUND;
        return;
    }

    # retrieve talk
    my $talk = Act::Talk->new(talk_id => $Request{path_info});

    # only organizer or submitter may see non accepted talk
    undef $talk
        if $talk
        && !$talk->{accepted}
        && !($Request{user}
             && ($Request{user}->user_id == $talk->user_id
                 || $Request{user}->is_orga));

    # retrieve talk's speaker info
    my $user;
    $user = Act::User->new(user_id => $talk->user_id)
        if $talk;

    unless ($talk && $user) {
        $Request{status} = NOT_FOUND;
        warn "unknown talk: $Request{path_info}";
        return;
    };

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        %$talk,
        user => $user,
    );
    $template->process('talk/show');
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
