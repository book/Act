package Act::Handler::Event::Show;
use strict;
use parent 'Act::Handler';
use Act::Config;
use Act::Template::HTML;
use Act::Event;
use Act::Abstract;

sub handler
{
    # retrieve event_id
    my $event_id = $Request{path_info};
    unless ($event_id =~ /^\d+$/) {
        $Request{status} = 404;
        return;
    }

    # retrieve event
    my $event = Act::Event->new(
        event_id => $event_id,
        $Request{conference} ? ( conf_id => $Request{conference} ) : (),
    );

    if ( ! defined $event ) {
        $Request{status} = 404;
        return;
    }

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( %$event, chunked_abstract => Act::Abstract::chunked( $event->abstract ) );
    $template->process('event/show');
    return;
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
