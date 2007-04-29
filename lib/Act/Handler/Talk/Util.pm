package Act::Handler::Talk::Util;
use strict;
use Act::Config;
use Act::Email;
use Act::Template;
use Act::User;

# optional email notification when a talk is accepted
sub notify_accept
{
    return unless $Config->talks_submissions_notify_address
               && $Config->talks_notify_accept;

    my $talk = shift;
    my $user = Act::User->new(user_id => $talk->user_id);

    # determine which language to send the notification in
    local $Request{language} = $Config->talks_submissions_notify_language
                            || $Request{language}
                            || $Config->general_default_language;

    # generate subject and body from templates
    my $template = Act::Template->new;
    my %output;
    for my $slot (qw(subject body)) {
        $template->variables(talk => $talk, user => $user);
        $template->process("talk/notify_accept_$slot", \$output{$slot});
    }
    # send the notification email
    Act::Email::send(
        from    => $Config->talks_submissions_notify_address,
        to      => $user->email,
        %output,
    );
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Util - shared routines for talk handlers

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
