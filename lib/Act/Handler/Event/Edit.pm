package Act::Handler::Event::Edit;

use strict;
use parent 'Act::Handler';
use DateTime::TimeZone;
use Act::Config;
use Act::Event;
use Act::Form;
use Act::Template::HTML;
use Act::Template;
use Act::Util;

# form
my $form = Act::Form->new(
  required => [qw( title abstract )],
  optional => [qw( url_abstract duration date time room delete )],
  constraints => {
     duration     => 'numeric',
     url_abstract => 'url',
     date         => 'date',
     time         => 'time',
     room         => sub { exists $Config->rooms->{$_[0]} or $_[0] =~ /^(?:out|venue|sidetrack)$/},
  }
);

sub handler {

    unless ( $Request{user}->is_talks_admin) {
        $Request{status} = 404;
        return;
    }
    my $template = Act::Template::HTML->new();
    my $fields;
    my $sdate = format_datetime_string($Config->talks_start_date);
    my $edate = format_datetime_string($Config->talks_end_date);
    my @dates = ($sdate->clone->truncate(to => 'day' ));
    push @dates, $_
        while (($_ = $dates[-1]->clone->add( days => 1 ) ) < $edate );

    # get the event
    my $event;
    $event = Act::Event->new(
        event_id  => $Request{args}{event_id},
        conf_id   => $Request{conference},
    ) if exists $Request{args}{event_id};

    # cannot edit non-existent events
    if( exists $Request{args}{event_id} and not defined $event ) {
        $Request{status} = 404;
        return;
    }

    # automatically compute the return URL
    my $referer = $Request{r}->header_in('Referer');
    $Request{args}{return_url} ||= $referer
        if $referer =~ m{/(?:schedule)};

    if ($Request{args}{submit}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        # apply default values
        $fields->{duration} ||= 0;

        # is the date in range?
        unless ( ! $fields->{date}
              or ! $fields->{time}
              or exists $form->{invalid}{date}
              or exists $form->{invalid}{time} ) {
            $fields->{datetime} = format_datetime_string("$fields->{date} $fields->{time}:00");
            if ( $fields->{datetime} > $edate or
                 $fields->{datetime} < $sdate ) {
                $form->{invalid}{period} = 'invalid';
                $ok = 0;
            }
        }

        if ($ok) {
            # update existing event
            if( defined $event ) { 
                if( $fields->{delete} ) {
                    $event->delete;
                    $template->variables(%$fields);
                    $template->process('event/removed');
                    return;
                }
                else { $event->update( %$fields ); }
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

            # return to the referring URL if needed
            return Act::Util::redirect( $Request{args}{return_url} )
                if $Request{args}{return_url};
        }
        else {
            # map errors
            $form->{invalid}{title}        && push @errors, 'ERR_TITLE';
            $form->{invalid}{abstract}     && push @errors, 'ERR_ABSTRACT';
            $form->{invalid}{duration}     && push @errors, 'ERR_DURATION';
            $form->{invalid}{url_abstract} && push @errors, 'ERR_URL_ABSTRACT';
            $form->{invalid}{date}         && push @errors, 'ERR_DATE';
            $form->{invalid}{time}         && push @errors, 'ERR_TIME';
            $form->{invalid}{period}       && push @errors, 'ERR_DATERANGE';
            $form->{invalid}{room}         && push @errors, 'ERR_ROOM';
        }
        $template->variables(errors => \@errors);
    }

    # display the event submission form
    $template->variables(
        return_url => $Request{args}{return_url},
        dates => \@dates, defined $event ? ( %$event ) : ( %$fields ),
        rooms => { %{ $Config->rooms },
                   map { $_ => localize("room_$_") } qw(venue out sidetrack),
                 },
    );
    $template->process('event/add');
    return;
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

