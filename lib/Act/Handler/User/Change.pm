package Act::Handler::User::Change;

use DateTime::TimeZone;
 
use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

# registration form
my $form = Act::Form->new(
  required => [qw(first_name last_name email country)],
  optional => [qw(im bio civility email_hide gpg_pub_key im pause_id monk_id pm_group pm_group_url timezone town web_page)],
  dependencies => {
    pseudonymous => [qw(nick_name)],
  },
  constraints => {
    email        => 'email',
    monk_id      => 'numeric',
    pm_group_url => 'url',
    web_page     => 'url',
    pm_group     => sub { $_[0] =~ /\.pm$/ },
  }
);

sub handler
{
    my $template = Act::Template::HTML->new();
    my $fields = {};

    if ($Request{args}{join}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        if ($ok) {
            # update user
            $Request{user}->update(%$fields);
        }
        else {
            # map errors
            $form->{invalid}{first_name} && push @errors, 'ERR_FIRST_NAME';
            $form->{invalid}{last_name}  && push @errors, 'ERR_LAST_NAME';
            $form->{invalid}{country}    && push @errors, 'ERR_COUNTRY';
            $form->{invalid}{nick_name}  && push @errors, 'ERR_NICK';
            $form->{invalid}{pm_group}   && push @errors, 'ERR_PMGROUP';
            $form->{invalid}{web_page}   && push @errors, 'ERR_WEBPAGE';
            $form->{invalid}{monk_id}    && push @errors, 'ERR_MONKID';
            $form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
            $form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';
        }
        $template->variables(errors => \@errors);
    }
    else {
        $fields = $Request{user};
    }
    # display form
    $template->variables(
        civilities => Act::Util::get_translations('users', 'civility'),
        countries  => Act::Country::CountryNames(),
        timezones  => [ DateTime::TimeZone::all_names() ],
        %$fields
    );
    $template->process('user/change');
}

1;
