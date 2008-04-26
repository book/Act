package Act::Handler::Talk::MySchedule;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use Act::Handler::Talk::Schedule;
use strict;

sub handler {

    return Act::Util::redirect(make_uri('register'))
      unless $Request{user}->has_registered;

    my @ts = map Act::TimeSlot::upgrade($_), @{ $Request{user}->my_talks };
    my %schedule = Act::Handler::Talk::Schedule::compute_schedule(@ts);

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        %schedule,
        todo     => [],
    );
    $template->process('talk/schedule');
}

1;

=head1 NAME

Act::Handler::Talk::MySchedule - Compute and display the user's personnal schedule

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
