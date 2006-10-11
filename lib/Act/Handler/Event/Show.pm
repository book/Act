package Act::Handler::Event::Show;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Event;
use Act::Abstract;

sub handler
{
    # retrieve event_id
    my $event_id = $Request{path_info};
    unless ($event_id =~ /^\d+$/) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # retrieve event
    my $event = Act::Event->new(
        event_id => $event_id,
        $Request{conference} ? ( conf_id => $Request{conference} ) : (),
    );

    if ( ! defined $event ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( %$event, chunked_abstract => Act::Abstract::chunked( $event->abstract ) );
    $template->process('event/show');
}

1;
__END__

=head1 NAME

Act::Handler::User::Show - show userinfo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
