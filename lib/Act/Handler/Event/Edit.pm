package Act::Handler::Event::Edit;

use strict;
use DateTime::TimeZone;
 
use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::Util;
use Act::Event;
use Act::Template;

# form
my $form = Act::Form->new(
  required => [qw( title abstract )],
  optional => [qw( url_abstract duration datetime )],
  constraints => {
     duration     => sub { $_[0] =~ /^\d+$/ },
     url_abstract => 'url',
  }
);

sub handler {

    unless ( $Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new();
    my $fields;

    # get the event
    my $event;
    $event = Act::Event->new(
        event_id  => $Request{args}{event_id},
        conf_id   => $Request{conference},
    ) if exists $Request{args}{event_id};

    # cannot edit non-existent events
    if( exists $Request{args}{event_id} and not defined $event ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    if ($Request{args}{submit}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        if ($ok) {
            # update existing event
            if( defined $event ) { 
                my $tbefore = $event->clone;
                $event->update( %$fields );
            }
            # insert new event
            else {
                $event = Act::Event->create(
                    %$fields,
                    conf_id   => $Request{conference},
                );
                # thanks, come again
                $template->variables(%$fields, event_id => $event->event_id);
                $template->process('event/added');

                return;
            }
        }
        else {
            # map errors
            $form->{invalid}{title}        && push @errors, 'ERR_TITLE';
            $form->{invalid}{abstract}     && push @errors, 'ERR_ABSTRACT';
            $form->{invalid}{duration}     && push @errors, 'ERR_DURATION';
            $form->{invalid}{url_abstract} && push @errors, 'ERR_URL_ABSTRACT';
        }
        $template->variables(errors => \@errors);
    }

    # display the event submission form
    $template->variables( defined $event ? ( %$event ) : ( %$fields ) );
    $template->process('event/add');
}

1;

=head1 NAME

Act::Handler::Event::Edit - Create or edit a event in the Act database

=head1 SYNOPSIS

  [events]
  submissions_notify_address  = address@domain
  submissions_notify_language = fr

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut

