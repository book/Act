package Act::Handler::User::Change;

use strict;
use DateTime::TimeZone;
 
use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

# participation fields
my @partfields = qw(tshirt_size nb_family);

# registration form
my @form_params = (
  required => [qw(first_name last_name email country)],
  filters => {
     email    => sub { lc shift },
     pm_group => sub { ucfirst lc shift },
  },
  dependencies => {
    pseudonymous => [qw(nick_name)],
  },
  constraints => {
    email        => 'email',
    monk_id      => 'numeric',
    nb_family    => 'numeric',
    pm_group_url => 'url',
    web_page     => 'url',
    company_url  => 'url',
    pm_group     => sub { $_[0] =~ /\.pm$/ },
    tshirt_size  => sub { $_[0] =~ /^(?:S|M|X{0,2}L)$/ },
  }
);

sub handler
{
    my $template = Act::Template::HTML->new();
    my $fields;
    my $form = Act::Form->new( @form_params, 
        optional => [qw(im civility email_hide gpg_pub_key im pause_id
                        monk_id pm_group pm_group_url timezone town web_page
                        company company_url address ),
                        @partfields,
                        map { "bio_$_" } keys %{ $Config->languages } ]
    );

    if ($Request{args}{join}) {
        # form has been submitted
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        if ($ok) {
            # extract participation data
            my %part;
            @part{@partfields} = delete @$fields{@partfields};

            # extract bio data
            my %bio = map { $_ => '' } keys %{ $Config->languages };
            for my $lang ( map { /^bio_(.*)/; $1 ? ($1) : () } keys %$fields )
            {
                $bio{$lang} = delete $fields->{"bio_$lang"};
            }

            # update user
            $Request{user}->update(%$fields, participation => \%part,
                                             bio => \%bio);
            @$fields{@partfields} = @part{@partfields};
            $fields->{bio} = \%bio;
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
            $form->{invalid}{nb_family}  && push @errors, 'ERR_NBFAMILY';
            $form->{invalid}{tshirt_size} && push @errors, 'ERR_TSHIRT';
            $form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
            $form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';
            $form->{invalid}{web_page}     && push @errors, 'ERR_WEBPAGE';
            $form->{invalid}{pm_group_url} && push @errors, 'ERR_PM_URL';
            $form->{invalid}{company_url}  && push @errors, 'ERR_COMPANY_URL';
        }
        $template->variables(errors => \@errors);
    }
    else {
        $fields = $Request{user};
        # deep copy bios to avoid double encoding issue
        $fields->{bio} = {%{$Request{user}->bio}};

        # participation to this conference
        if (my $part = $Request{user}->participation) {
            @$fields{@partfields} = @$part{@partfields};
        }
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
__END__

=head1 NAME

Act::Handler::User::Change - update a user's profile

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
