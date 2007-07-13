package Act::Handler::User::ChangePassword;

use strict;
 
use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

my $form = Act::Form->new(
  required => [qw(newpassword1 newpassword2)],
  filters => {
     newpassword1 => sub { lc shift },
     newpassword2 => sub { lc shift },
  },
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

        # both fields need to be the same
        if ( $fields->{newpassword1} ne $fields->{newpassword2} ) {
             $form->{invalid}{same} = 1;
             $ok = 0;
        }

        if ($ok) {
            # update user
            $Request{user}->update(
                passwd => Act::Util::crypt_password( $fields->{newpassword1} )
            );
            # redirect to user's main page
            return Act::Util::redirect(make_uri('main'));
        }
        else {
            # map errors
            $form->{invalid}{newpassword1} && push @errors, 'ERR_PASSWORD_1';
            $form->{invalid}{newpassword2} && push @errors, 'ERR_PASSWORD_2';
            $form->{invalid}{same}         && push @errors, 'ERR_SAME';
        }
        $template->variables(errors => \@errors);
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
