package Act::Handler::Talk::Change;

use strict;
use DateTime::TimeZone;
 
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Talk;
use Act::Util;

# participation fields
my @partfields = qw(tshirt_size nb_family);

# registration form
my $form = Act::Form->new(
  required => [qw(title abstract)],
  optional => [qw(url_abstract url_talk comment duration is_lightning
                  accepted confirmed)],
  constraints => {
     duration     => sub { $_[0] =~ /^(lightning|\d+)$/ },
     url_abstract => 'url',
     url_talk     => 'url',
  }
);

sub handler
{
    unless ($Config->talks_submissions_open or $Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new();
    my $fields;

    # get the talk
    my $talk = Act::Talk->new(
        talk_id   => $Request{args}{talk_id},
        conf_id   => $Request{conference},
    );

    # cannot change non-existent talks
    if( not defined $talk ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    if ($Request{args}{submit}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        # organizer specifies user id
        my $user_id = $Request{user}->is_orga
                    ? $Request{args}{user_id}
                    : $Request{user}->user_id;

        if ($Request{user}->is_orga) {
            $fields->{user_id} = $user_id;
            if ($user_id =~ /^\d+$/) {
                my $u = Act::User->new(user_id => $user_id);
                unless ($u && $u->participation) {
                    $form->{invalid}{user_id} = 'invalid';
                    $ok = 0;
                }
            }
        } else {
            # a normal user can only edit his own talks
            if( $talk->user_id != $Request{user}->user_id ) {
                require Act::Handler::Talk::Show;
                Act::Handler::Talk::Show->handler;
                return;
            }
            # a normal user cannot comment a talk or edit the duration
            delete @{$fields}{qw( comment is_lightning )};
            $fields->{duration} = $talk->lightning
                                ? 'lightning' : $talk->duration;
            $fields->{accepted} = $talk->accepted;
        }

        if( not $fields->{duration} and not $fields->{is_lightning} ){
            $form->{invalid}{duration} = 'invalid';
            $ok = 0;
        };

        if ($ok) {
            # handle is_lightning (from orga's form)
            $fields->{duration} = 'lightning' if delete $fields->{is_lightning};
            $fields->{lightning} = 0;
            # boolean fields
            $fields->{$_} = $fields->{$_} ? 1 : 0 for qw( accepted confirmed );

            # separate lightning from duration
            if ($fields->{duration} eq 'lightning') {
                $fields->{lightning} = 1;
                $fields->{duration}  = undef;
            }
            $talk->update( %$fields );
        }
        else {
            # map errors
            $form->{invalid}{user_id}      && push @errors, 'ERR_USER';
            $form->{invalid}{title}        && push @errors, 'ERR_TITLE';
            $form->{invalid}{abstract}     && push @errors, 'ERR_ABSTRACT';
            $form->{invalid}{duration}     && push @errors, 'ERR_DURATION';
            $form->{invalid}{url_abstract} && push @errors, 'ERR_URL_ABSTRACT';
            $form->{invalid}{url_talk}     && push @errors, 'ERR_URL_TALK';
        }
        $template->variables(errors => \@errors);
    }

    # display the talk submission form
    $template->variables(
        %$talk,
        duration => ( $talk->lightning ? 'lightning' : $talk->duration )
    );
    $template->variables(
        users => [ sort { lc $a->{last_name} cmp lc $b->{last_name} }
                   @{Act::User->get_users(conf_id => $Request{conference})}
                 ],
    ) if $Request{user}->is_orga;
    $template->process('talk/add');
}

1;

=head1 NAME

Act::Handler::Talk::Change - Edit a talk

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
