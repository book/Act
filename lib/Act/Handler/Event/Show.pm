package Act::Handler::Event::Show;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Event;

sub handler
{
    # retrieve event
    my $event = Act::Event->new(
        event_id => $Request{path_info},
        $Request{conference} ? ( conf_id => $Request{conference} ) : (),
    );

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( %$event );
    $template->process('event/show');
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
