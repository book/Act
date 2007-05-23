package Act::Handler::Track::Edit;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::Track;
use Act::Util;

# form
my $form = Act::Form->new(
  required => [qw( title )],
  optional => [qw( description delete )],
);

sub handler {

    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new();
    my $fields;

    # get the track
    my $track;
    $track = Act::Track->new(
        track_id  => $Request{args}{track_id},
        conf_id   => $Request{conference},
    ) if exists $Request{args}{track_id};

    # cannot edit non-existent track
    if (exists $Request{args}{track_id} and not defined $track) {
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
            if (defined $track) { 
                if ($fields->{delete} ) {
                    # delete existing track
                    $track->delete;
                    # redirect to track list
                    return Act::Util::redirect(make_uri('tracks'));
                }
                else {
                    # update existing track
                    $track->update( %$fields );
                }
            }
            # insert new track
            else {
                $track = Act::Track->create(
                    %$fields,
                    conf_id   => $Request{conference},
                );
                # redirect to track list
                return Act::Util::redirect(make_uri('tracks'));
            }
        }
        else {
            # map errors
            $form->{invalid}{title} && push @errors, 'ERR_TITLE';
        }
        $template->variables(errors => \@errors);
    }

    # display the track submission form
    $template->variables(defined $track ? %$track : %$fields);
    $template->process('track/edit');
}

1;

=head1 NAME

Act::Handler::Track::Edit - Create or edit a track

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
