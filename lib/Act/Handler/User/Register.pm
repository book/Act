package Act::Handler::User::Register;

use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

# registration form
my $form = Act::Form->new(
  required => [qw(login first_name last_name email country)],
  filters => {
     login    => sub { lc shift },
     email    => sub { lc shift },
  },
  constraints => {
     login => sub { $_[0] =~ /^[A-Za-z0-9_]{3,}$/ },
     email => 'email',
  }
);

sub handler
{
    # special case of logged in users!
    if( defined $Request{user} ) {
        # already registered, move along
        return Act::Util::redirect(make_uri('main'))
          if defined $Request{user}->participation;

        # user logged in but not registered (yet)
        if ($Request{args}{join}) {
            # create a new participation to this conference
            my $sth = $Request{dbh}->prepare_cached(
                "INSERT INTO participations (user_id, conf_id) VALUES (?,?);"
            );
            $sth->execute($Request{user}->user_id, $Request{conference});
            $sth->finish();
            $Request{dbh}->commit;
            return Act::Util::redirect(make_uri('main'))
        }
        else {
            my $template = Act::Template::HTML->new();
            $template->process('user/register');
            return;
        }
    }

    my $template = Act::Template::HTML->new();
    my $fields = {};

    if ($Request{args}{join}) {
        # form has been submitted
        my @errors;
warn "\njoining\n";
        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};
warn "ok = $ok\n";
        if ($ok) {
            # check for existing user
warn "check for existing\n";
            if (Act::User->new(login => $fields->{login})) {
                push @errors, 'ERR_IDENTIFIER_EXISTS';
            }
            elsif (Act::User->new(email => $fields->{email})) {
                push @errors, 'ERR_EMAIL_EXISTS';
            }
            # create this user
            else {
                # generate a random password
warn "gen_password\n";
                my ($clear_passwd, $crypt_passwd) = Act::Util::gen_password();
                $fields->{passwd} = $crypt_passwd;

                # insert user in database
                # and participation to this conference
warn "before create\n";
                my $user = Act::User->create(
                    %$fields,
                    participation => { },
                );
warn "after create\n\n";

                # display "added page"
                $template->variables(
                    clear_passwd => $clear_passwd,
                    %$fields
                );
                $template->process('user/added');
                return;
            }
        }
        else {
            # map errors
            $form->{invalid}{login}      && push @errors, 'ERR_IDENTIFIER';
            $form->{invalid}{first_name} && push @errors, 'ERR_FIRST_NAME';
            $form->{invalid}{last_name}  && push @errors, 'ERR_LAST_NAME';
            $form->{invalid}{country}    && push @errors, 'ERR_COUNTRY';
            $form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
            $form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';

        }
        $template->variables(errors => \@errors);
    }
    # display the registration form
    $template->variables(
        countries => Act::Country::CountryNames(),
        %$fields
    );
    $template->process('user/add');
}

1;

=head1 NAME

Act::Handler::User::Register - create a new user

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
