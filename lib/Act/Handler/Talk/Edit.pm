package Act::Handler::Talk::Edit;

use strict;
use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use DateTime::Format::Pg ();
use Text::Diff ();
 
use Act::Config;
use Act::Email;
use Act::Form;
use Act::I18N;
use Act::Talk;
use Act::Template;
use Act::Template::HTML;
use Act::Track;
use Act::User;
use Act::Util;
use Act::Handler::Talk::Util;

# form
my $form = Act::Form->new(
  required => [qw(title abstract)],
  optional => [qw(url_abstract url_talk comment duration is_lightning
                  accepted confirmed date time room delete track_id level)],
  filters  => {
     track_id => sub { $_[0] || undef },
     map { $_ => sub { $_[0] ? 1 : 0 } } qw(accepted confirmed is_lightning)
  },
  constraints => {
     duration     => sub { $_[0] =~ /^(lightning|\d+)$/ },
     url_abstract => 'url',
     url_talk     => 'url',
     date         => 'date',
     time         => 'time',
     room         => sub { exists $Config->rooms->{$_[0]} },
     level        => sub { !$Config->talks_levels
                           || ($_[0] =~ /^\d+$/ && $_[0] >= 1 && $_[0] <= $Config->talks_levels)
                     },
  }
);

sub handler {

    my $template = Act::Template::HTML->new();
    my $fields;
    my $sdate = DateTime::Format::Pg->parse_timestamp($Config->talks_start_date);
    my $edate = DateTime::Format::Pg->parse_timestamp($Config->talks_end_date);
    my @dates = ($sdate->clone->truncate(to => 'day' ));
    push @dates, $_
        while (($_ = $dates[-1]->clone->add( days => 1 ) ) < $edate );

    # get the talk
    my $talk;
    if (exists $Request{args}{talk_id}) {
        $talk = Act::Talk->new(
            talk_id   => $Request{args}{talk_id},
            conf_id   => $Request{conference},
        );
        unless ($talk) {
            # cannot edit non-existent talk
            $Request{status} = NOT_FOUND;
            return;
        }
    }
    # orgas can submit/edit talks anytime
    # regular users can submit new talks when submissions_open
    # and edit existing talks when edition_open or submission_open
    #
    unless ($Request{user}->is_orga) {
        unless ( ($talk && $talk->user_id == $Request{user}->user_id
                        && ($Config->talks_edition_open || $Config->talks_submissions_open))
                || $Config->talks_submissions_open )
        {
            $Request{status} = NOT_FOUND;
            return;
        }
    }
    # not registered!
    return Act::Util::redirect(make_uri('register'))
      unless $Request{user}->has_registered;

    if ($Request{args}{submit}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = { accepted => 0, confirmed => 0, track_id => undef, %{$form->{fields}} };

        # organizer specifies user id
        my $user_id = $Request{user}->is_orga
                    ? $Request{args}{user_id}
                    : $Request{user}->user_id;

        if ($Request{user}->is_orga) {
            $fields->{user_id} = $user_id;
            # does the user participate?
            if ($user_id =~ /^\d+$/) {
                my $u = Act::User->new(user_id => $user_id);
                unless ($u && $u->participation) {
                    $form->{invalid}{user_id} = 'invalid';
                    $ok = 0;
                }
            }
            # is the date in range?
            unless ( ! $fields->{date}   
                  or ! $fields->{time}
                  or exists $form->{invalid}{date}
                  or exists $form->{invalid}{time} ) {
                $fields->{datetime} = DateTime::Format::Pg->parse_timestamp("$fields->{date} $fields->{time}:00");
                if ( $fields->{datetime} > $edate or
                     $fields->{datetime} < $sdate ) {
                    $form->{invalid}{period} = 'invalid';
                    $ok = 0;
                }
            }
        }
        # normal user
        else {
            # cannot comment a talk or change the date/room
            delete @{$fields}{qw( is_lightning date time room )};
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
                if( $fields->{delete} ) {
                    # optional email notification ?
                    # notify('delete', $talk); # FIXME
                    $talk->delete;
                    $template->variables(%$fields);
                    $template->process('talk/removed');
                    return;
                }
                else {
                    my $tbefore = $talk->clone;
                    $talk->update( %$fields );

                    # optional email notifications
                    notify('update', $tbefore, $talk);
                    if (!$tbefore->accepted && $talk->accepted) {
                        Act::Handler::Talk::Util::notify_accept($talk);
                    }
                }
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
            $form->{invalid}{date}         && push @errors, 'ERR_DATE';
            $form->{invalid}{time}         && push @errors, 'ERR_TIME';
            $form->{invalid}{period}       && push @errors, 'ERR_DATERANGE';
            $form->{invalid}{room}         && push @errors, 'ERR_ROOM';
            $form->{invalid}{level}        && push @errors, 'ERR_LEVEL';
        }
        $template->variables(errors => \@errors);
    }

    # display the talk submission form
    $template->variables(
        levels => [ map $Config->get("levels_level$_\_name_$Request{language}"),
                    1 .. $Config->talks_levels ],
        defined $talk
        ? ( %$talk,
            duration => ( $talk->lightning ? 'lightning' : $talk->duration ) )
        : ( %$fields )
    );
    $template->variables(
        dates => \@dates,
        users => [ sort { lc $a->{last_name} cmp lc $b->{last_name} }
                   @{Act::User->get_users(conf_id => $Request{conference})}
                 ],
        rooms => $Config->rooms,
        tracks => Act::Track->get_tracks( conf_id => $Request{conference}),
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
        my (@diff, $adiff);
        if ($tbefore) {
            for my $field (keys %$talk) {
                if ($field eq 'abstract') {
                    my ($a1, $a2) = ($tbefore->abstract, $talk->abstract);
                    if ($a1 ne $a2) {
                        substr($_, length($_), 1) ne "\n" and $_ .= "\n" for ($a1, $a2);
                        $adiff = Text::Diff::diff(\$a1, \$a2);
                    }
                }
                elsif ($field eq 'datetime') {
                    push @diff, 'datetime'
                        if   $tbefore->datetime && !$talk->datetime
                         || !$tbefore->datetime &&  $talk->datetime
                         || DateTime->compare($tbefore->datetime, $talk->datetime);
                }
                elsif ($field eq 'level') {
                    if ($tbefore->level != $talk->level) {
                        for my $t ($tbefore, $talk) {
                            $t->{audience} = $Config->get("levels_level" . $t->level ."_name_$Request{language}")
                                if $t->level;
                        }
                        push @diff, 'audience';
                    }
                }
                elsif ($field eq 'track_id') {
                    if (($tbefore->track_id || 0) != ($talk->track_id || 0)) {
                        for my $t ($tbefore, $talk) {
                            $t->{track} = Act::Track->new(track_id => $t->track_id)->title
                                if $t->track_id;
                        }
                        push @diff, 'track';
                    }
                }
                else {
                    # simple fields
                    push @diff, $field
                        if $tbefore->$field ne $talk->$field;
                }
            }
            return unless @diff || $adiff;
        }

        # determine which language to send the notification in
        local $Request{language} = $Config->talks_submissions_notify_language
                                || $Request{language}
                                || $Config->general_default_language;
        local $Request{loc} = Act::I18N->get_handle($Request{language});

        # additional talk information
        $talk->{track} = Act::Track->new(track_id => $talk->track_id)->title
                                if $talk->track_id;
        $talk->{audience} = $Config->get("levels_level" . $talk->level ."_name_$Request{language}")
            if $Config->talks_levels;

        # generate subject and body from templates
        my $template = Act::Template->new;
        my %output;
        for my $slot (qw(subject body)) {
            $template->variables(
                op   => $op,
                talk => $talk,
                user => $user,
            );
            if ($slot eq 'body') {
                $template->variables(
                        diff    => \@diff,
                        tbefore => $tbefore)
                    if @diff;
                $template->variables(adiff => $adiff)
                    if $adiff;
            }
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

