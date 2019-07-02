package Act::Handler::User::ChangePassword;

use strict;

use Act::Auth; 
use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;
use Act::TwoStep;
use Digest::MD5 ();

my $form = Act::Form->new(
  required => [qw(newpassword1 newpassword2)],
  optional => [qw(oldpassword)],
  filters => {
     newpassword1 => sub { shift },
     newpassword2 => sub { shift },
  },
);
# twostep form
my $twostep_form = Act::Form->new(
  optional => [qw(login email)],
  filters => {
     login    => sub { lc shift },
     email    => sub { lc shift },
  },
  constraints => {
    email     => 'email',
  },
  global => [ sub {
    my $fields = shift;
    # at least one of the fields must be provided
    my %key = map { $_ => $fields->{$_} } grep $fields->{$_}, qw(login email);
    unless (%key) {
        $fields->{error} = 'ERR_LOGIN_OR_EMAIL';
        return;
    }
    # search for user
    $fields->{user} = Act::User->new(%key);
    unless ($fields->{user}) {
        $fields->{error} = 'ERR_USER_NOT_FOUND';
        return;
    }
    return 1;
  } ],
);
# twostep template
my $twostep_template = 'user/twostep_change_password';

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

        my ($token, $token_data);
        if ($Request{user}) { # 
            # compare passwords
            my $digest = Digest::MD5->new;
            $digest->add($fields->{oldpassword});
            if ( $digest->b64digest() ne $Request{user}{passwd} ) {
                # compare lc passwords (r1549)
                $digest->reset;
                $digest->add(lc $fields->{oldpassword});
                if ( $digest->b64digest() ne $Request{user}{passwd} ) {
                    $ok = 0;
                    $form->{invalid}{oldpassword} = 1;
                }
            }
        }
        else { # must have a valid twostep token if not logged in
            ($token, $token_data) = Act::TwoStep::verify_form()
                or return;
        }

        # both fields need to be the same
        if ( $fields->{newpassword1} ne $fields->{newpassword2} ) {
             $form->{invalid}{same} = 1;
             $ok = 0;
        }

        if ($ok) {
            # remove token and authenticate user if twostep
            unless ($Request{user}) {
                my $user = Act::User->new(user_id => $token_data)
                    or die "unknown user_id: $token_data\n";
                my $sid = Act::Util::create_session($user);
                Act::Auth->send_cookie($sid);
                Act::TwoStep::remove($token);
            }
            # update user
            $Request{user}->update(
                passwd => Act::Util::crypt_password( $fields->{newpassword1} )
            );

            # redirect to user's main page
            return Act::Util::redirect(make_uri('main'));
        }
        else {
            # map errors
            $form->{invalid}{oldpassword}  && push @errors, 'ERR_OLD_PASSWORD';
            $form->{invalid}{newpassword1} && push @errors, 'ERR_PASSWORD_1';
            $form->{invalid}{newpassword2} && push @errors, 'ERR_PASSWORD_2';
            $form->{invalid}{same}         && push @errors, 'ERR_SAME';
        }
        $template->variables(errors => \@errors);
    }
    elsif ($Request{args}{twostepsubmit}) {     # two-step form has been submitted
        # validate form and create a new token
        if (Act::TwoStep::create(
           $twostep_template, $twostep_form,
           'user/twostep_change_password_email_subject', 'user/twostep_change_password_email_body',
                sub { $twostep_form->{fields}{user}{email} },
                sub { my @errors;
                      $twostep_form->{invalid}{global} && push @errors, $twostep_form->{fields}{error};
                      $twostep_form->{invalid}{email} eq 'email' && push @errors, 'ERR_EMAIL_SYNTAX';
                      return \@errors;
                    },
                sub { $twostep_form->{fields}{user}{user_id} },
        )) {
            # twostep form is valid, display confirmation page
            $template->process('user/twostep_change_password_ok');
        }
        return;
    }
    elsif (!$Request{user}) {       # user not logged in
        # do we have a twostep token in the uri?
        Act::TwoStep::verify_uri($twostep_template)
            or return;
    }
    # display form
    $template->process('user/change_password');
}

1;
__END__

=head1 NAME

Act::Handler::User::ChangePassword - change a user's password

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
