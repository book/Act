package Act::Handler::Talk::Register;
use strict;

use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Country;
use Act::Form;
use Act::Talk;
use Act::Template::HTML;
use Act::Util;

# registration form
my $form = Act::Form->new(
  required => [qw(title abstract duration)],
  optional => [qw(url_abstract url_talk)],
  constraints => {
     duration     => sub { $_[0] eq 'lightning' || exists $Config->talks_durations->{$_[0]} },
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
        }
        if ($ok) {
            # separate lightning from duration
            if ($fields->{duration} eq 'lightning') {
                $fields->{lightning} = 't';
                delete $fields->{duration};
            }
            # add this talk
            Act::Talk->create(
              %$fields,
              user_id   => $user_id,
              conf_id   => $Request{conference},
            );
            # thanks, come again
            $template->variables(%$fields);
            $template->process('talk/added');
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
        %$fields
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

Act::Handler::Talk::Register - create a new talk

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
