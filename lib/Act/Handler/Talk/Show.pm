package Act::Handler::Talk::Show;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::Abstract;

sub handler
{
    # retrieve talk_id
    my $talk_id = $Request{path_info};
    unless ($talk_id =~ /^\d+$/) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # retrieve talk
    my $talk = Act::Talk->new(
        talk_id => $talk_id,
        $Request{conference} ? ( conf_id => $Request{conference} ) : ()
    );

    # available only if submissions open or organizer
    unless ($talk
            && ( $Config->talks_show_all
                 || $talk->accepted
                 || ($Request{user} && $Request{user}->is_orga)
                 || ($Request{user} && $Request{user}->user_id == $talk->user_id) ) )
    {
        $Request{status} = NOT_FOUND;
        return;
    }

    # only organizer or submitter may see non accepted talk
    # except when the config says show_all !
    undef $talk
        if !$Config->talks_show_all
        && $talk
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
        return;
    };

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        %$talk,
        chunked_abstract => Act::Abstract::chunked( $talk->abstract ),
        user => $user,
    );
    $template->variables(
        level => $Config->get("levels_level" . $talk->level . "_name_$Request{language}"),
    ) if $Config->talks_levels;
    $template->process('talk/show');
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
