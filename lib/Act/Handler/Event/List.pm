package Act::Handler::Event::List;
use strict;
use parent 'Act::Handler';
use Act::Config;
use Act::Template::HTML;
use Act::Event;

sub handler
{
    # retrieve events and speaker info
    my $events = Act::Event->get_events(conf_id => $Request{conference});

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        events => [ sort { $a->datetime cmp $b->datetime } @$events ],
    ); 
    $template->process('event/list');
    return;
}

1;
__END__

=head1 NAME

Act::Handler::Event::List - show all events

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
