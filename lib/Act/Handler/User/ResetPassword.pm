package Act::Handler::User::ResetPassword;

use strict;
 
use Act::Config;
use Act::Email;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

# reset password form
my $form = Act::Form->new(
  optional => [qw(login email)],
  filters => {
     login    => sub { lc shift },
     email    => sub { lc shift },
  },
  constraints => {
    email        => 'email',
  }
);

sub handler
{
    my $template = Act::Template::HTML->new();
    my $fields;

    if ($Request{args}{ok}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        # exactly one of the fields must be provided
        my %key;
        if ($ok) {
            for my $f (qw(login email)) {
                if ($fields->{$f}) {
                    if (%key) {
                        $ok = 0;
                        last;
                    }
                    else {
                        %key = ($f => $fields->{$f});
                    }
                }
            }
            unless ($ok && %key) {
                $ok = 0;
                push @errors, 'ERR_LOGIN_OR_EMAIL';
            }
        }
        if ($ok) {

            # look for user
            my $user = Act::User->new(%key);

            if ($user) {
                # reset password
                my ($clear_passwd, $crypt_passwd) = Act::Util::gen_password();

                # update user
                $user->update(passwd => $crypt_passwd);

                # mail new password to user
                _send_email($user, $clear_passwd);

                # thanks for playing
                $template->variables(reset => 1);
            }
            else {
                push @errors, 'ERR_USER_NOT_FOUND';
            }
        }
        else {
            $form->{invalid}{email} eq 'email' && push @errors, 'ERR_EMAIL_SYNTAX';
        }
        $template->variables(errors => \@errors);
    }
    else {
        $fields = {};
    }
    # display form
    $template->variables(
        %$fields
    );
    $template->process('user/resetpassword');
}

sub _send_email
{
    my ($user, $clear_passwd) = @_;

    # generate subject and body from templates
    my $template = Act::Template->new;
    my %output;
    for my $slot (qw(subject body)) {
        $template->variables(
            user   => $user,
            passwd => $clear_passwd,
        );
        $template->process("user/reset_password_$slot", \$output{$slot});
    }
    # send the notification email
    Act::Email::send(
        from    => $Config->email_sender_address,
        to      => $user->email,
        %output,
    );
}

1;
__END__

=head1 NAME

Act::Handler::User::ResetPassword - reset a user's password

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
