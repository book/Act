package Act::Handler::Talk::Proceedings;
use strict;
use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::User;


sub handler {
    # retrieve talks and speaker info
    my $talks = Act::Talk->get_talks( conf_id => $Request{conference} );
    $_->{user} = Act::User->new( user_id => $_->user_id ) for @$talks;

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
        } @$talks
    ];

    # process the template
    my $template = Act::Template::HTML->new;
    $template->variables(
        talks   => $talks,
    ); 

    $template->process("talk/proceedings");
}

1;
__END__

=head1 NAME

Act::Handler::Talk::Proceedings - show proceedings

=head1 DESCRIPTION

Show proceedings: all talks in a big list, with the useful details.

See F<DEVDOC> for a complete discussion on handlers.

=cut
