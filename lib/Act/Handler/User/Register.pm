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
  constraints => {
     login => sub { $_[0] =~ /^[A-Za-z0-9_]{3,}$/ },
     email => 'email',
  }
);

sub handler
{
    # this is not for logged in users!
    defined($Request{user}) and die "don't call register() for logged users!";

    my $template = Act::Template::HTML->new();
    my $fields = {};

    if ($Request{args}{join}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        if ($ok) {
            $fields->{login} = lc $fields->{login};
            # check for existing user
            if (Act::User->new(login => $fields->{login})) {
                push @errors, 'ERR_IDENTIFIER_EXISTS';
            }
            # create this user
            else {
                # generate a random password
                my ($clear_passwd, $crypt_passwd) = Act::Util::gen_password();
                $fields->{passwd} = $crypt_passwd;

                # insert user in database
                # and participation to this conference
                my $user = Act::User->create(
                    %$fields,
                    participation => { },
                );

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
