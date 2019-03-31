package Act::Handler::Talk::Slides;
use strict;
use parent 'Act::Handler';

use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::User;

#
# handler()
# -------
sub handler {
    # retrieve talks and speaker info
    my $talks = Act::Talk->get_talks( conf_id => $Request{conference} );
    my @filtered_talks;

    for my $talk (@$talks) {
       next unless $talk->{url_talk}; # TODO this should move into get_talks

       # make the User object for the speaker
       $talk->{user} = Act::User->new( user_id => $talk->user_id );

       # default language
       $talk->{lang} ||= $Config->general_default_language;

       push @filtered_talks, $talk;
    }

    # sort talks
    $talks = [
        sort {
            $a->title cmp $b->title
        }
        grep {
               $Config->talks_show_all
            || $_->accepted
            || ($Request{user} && ( $Request{user}->is_talks_admin
                                 || $Request{user}->user_id == $_->user_id))
        } @filtered_talks
    ];

    # process the template
    my $template = Act::Template::HTML->new;
    $template->variables(
        talks   => $talks,
    ); 

    $template->process("talk/slides");
}


1;
__END__

=head1 NAME

Act::Handler::Talk::Slides - show proceedings

=head1 DESCRIPTION

Show slides: all talks with linked slides in a big list

See F<DEVDOC> for a complete discussion on handlers.

=cut
