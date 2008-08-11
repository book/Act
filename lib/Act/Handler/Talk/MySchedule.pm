package Act::Handler::Talk::MySchedule;
use strict;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use Act::Handler::Talk::Schedule;
use Act::Util;

sub handler {

    return Act::Util::redirect(make_uri('register'))
      unless $Request{user}->has_registered;

    my @ts = map Act::TimeSlot::upgrade($_),
             @{ Act::Event->get_events( conf_id => $Request{conference} ) },
             @{ $Request{user}->my_talks };
    my %schedule = Act::Handler::Talk::Schedule::compute_schedule(@ts);

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        %schedule,
        todo     => [],
    );
    $template->process('talk/myschedule');
}

1;

=head1 NAME

Act::Handler::Talk::MySchedule - Compute and display the user's personnal schedule

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
