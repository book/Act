package Act::Handler::Talk::Edit;

use strict;
use DateTime::TimeZone;
 
use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Talk;
use Act::Util;

use Act::Email;
use Act::Template;

# form
my $form = Act::Form->new(
  required => [qw(title abstract)],
  optional => [qw(url_abstract url_talk comment duration is_lightning
                  accepted confirmed)],
  filters  => {
     map { $_ => sub { $_[0] ? 1 : 0 } } qw(accepted confirmed is_lightning)
  },
  constraints => {
     duration     => sub { $_[0] =~ /^(lightning|\d+)$/ },
     url_abstract => 'url',
     url_talk     => 'url',
  }
);

sub handler {

    unless ($Config->talks_submissions_open or $Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new();
    my $fields;

    # get the talk
    my $talk;
    $talk = Act::Talk->new(
        talk_id   => $Request{args}{talk_id},
        conf_id   => $Request{conference},
    ) if exists $Request{args}{talk_id};

    # cannot edit non-existent talks
    if( exists $Request{args}{talk_id} and not defined $talk ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    if ($Request{args}{submit}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = { accepted => 0, confirmed => 0, %{$form->{fields}} };

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
        }
        # normal user
        else {
            # can only edit his own talks
            if( defined $talk and $talk->user_id != $Request{user}->user_id ) {
                $Request{status} = FORBIDDEN;
                return;
            }
            # cannot comment a talk
            delete @{$fields}{qw( comment is_lightning )};
            # cannot modify the duration
            if( defined $talk ) {
                $fields->{duration} = $talk->lightning
                                    ? 'lightning' : $talk->duration;
                $fields->{accepted} = $talk->accepted;
            }
            # limited duration choices for new talks
            else {
                unless ( exists $Config->talks_durations->{$fields->{duration}}
                         || $fields->{duration} eq 'lightning' ) {
                    $form->{invalid}{duration} = 'invalid';
                    $ok = 0;
                }
            }
        }

        if( not $fields->{duration} and not $fields->{is_lightning} ){
            $form->{invalid}{duration} = 'invalid';
            $ok = 0;
        };

        if ($ok) {
            # handle is_lightning (from orga's form)
            $fields->{duration} = 'lightning' if delete $fields->{is_lightning};
            $fields->{lightning} = 0;

            # separate lightning from duration
            if ($fields->{duration} eq 'lightning') {
                $fields->{lightning} = 1;
                $fields->{duration}  = undef;
            }

            # update existing talk
            if( defined $talk ) { 
                my $tbefore = $talk->clone;
                $talk->update( %$fields );

                # optional email notification
                notify('update', $tbefore, $talk);
            }
            # insert new talk
            else {
                $talk = Act::Talk->create(
                    %$fields,
                    user_id   => $user_id,
                    conf_id   => $Request{conference},
                );
                # thanks, come again
                $template->variables(%$fields, talk_id => $talk->talk_id);
                $template->process('talk/added');

                # optional email notification
                notify(insert => $talk);
                return;
            }
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
        defined $talk
        ? ( %$talk,
            duration => ( $talk->lightning ? 'lightning' : $talk->duration ) )
        : ( %$fields )
    );
    $template->variables(
        users => [ sort { lc $a->{last_name} cmp lc $b->{last_name} }
                   @{Act::User->get_users(conf_id => $Request{conference})}
                 ],
    ) if $Request{user}->is_orga;
    $template->process('talk/add');
}

# optional email notification when a talk is inserted or updated
sub notify
{
    if ($Config->talks_submissions_notify_address) {
        my ($op, $tbefore, $talk) = @_;
        if ($op eq 'insert') {
            $talk = $tbefore;
            undef $tbefore;
        }
        # user giving this talk
        my $user = Act::User->new(user_id => $talk->user_id);

        # diff with previous version if update
        my @diff;
        @diff = grep { $tbefore->$_ ne $talk->$_ } keys %$talk
            if $tbefore;

        # determine which language to send the notification in
        local $Request{language} = $Config->talks_submissions_notify_language
                                || $Request{language}
                                || $Config->general_default_language;

        # generate subject and body from templates
        my $template = Act::Template->new;
        my %output;
        for my $slot (qw(subject body)) {
            $template->variables(
                op   => $op,
                talk => $talk,
                user => $user,
            );
            $template->variables(
                diff => \@diff,
                tbefore => $tbefore,
            ) if $tbefore;

            $template->process("talk/notify_$slot", \$output{$slot});
        }
        # send the notification email
        Act::Email::send(
            from    => $Config->talks_submissions_notify_address,
            to      => $Config->talks_submissions_notify_address,
            %output,
        );
    }
}

1;

=head1 NAME

Act::Handler::Talk::Edit - Create or edit a talk in the Act database

=head1 SYNOPSIS

  [talks]
  submissions_notify_address  = address@domain
  submissions_notify_language = fr

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=over 4

=item notify

  notify(insert => $talk);
  notify(update => $talk_before, $talk);

Notifies the conference committee when a talk has been inserted or
updated.

=back

=cut

