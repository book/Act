package Act::Handler::User::Register;
use strict;

use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::TwoStep;
use Act::User;
use Act::Util;

use Apache::Constants qw(FORBIDDEN);
use DateTime;
use DateTime::Format::Pg;

# twostep form
my $twostep_form = Act::Form->new(
  required    => [qw(email)],
  filters     => { email => sub { lc shift } },
  constraints => { email => 'email' },
);

# twostep template filename
my $twostep_template = 'user/twostep_add';

# registration form
my $form = Act::Form->new(
  required => [qw(login first_name last_name email country tshirt )],
  optional => [qw( ignore_duplicates )],
  filters => {
     login    => sub { lc shift },
     email    => sub { lc shift },
     tshirt   => sub { uc shift },
  },
  constraints => {
     login => sub { $_[0] =~ /^[A-Za-z0-9_]{3,}$/ },
     email => 'email',
     tshirt => sub { $_[0] =~ /^(?:S|M|X{0,2}L)$/ },
  }
);

sub handler
{

    # conference is closed, do not POST
    if ( $Request{args}{join} ) {
        if ($Config->closed) {
            $Request{status} = FORBIDDEN;
            return;
        }
    }
    # special case of logged in users!
    if( defined $Request{user} ) {
        # already registered, move along
        return Act::Util::redirect(make_uri('main'))
          if defined $Request{user}->participation;

        # user logged in but not registered (yet)
        if ($Request{args}{join}) {
            # create a new participation to this conference
            my $sth = $Request{dbh}->prepare_cached(
                "INSERT INTO participations (user_id, conf_id, datetime, ip) VALUES (?,?, NOW(), ?);"
            );
            $sth->execute( $Request{user}->user_id, $Request{conference},
                           $Request{r}->connection->remote_ip );
            $sth->finish();
            $Request{dbh}->commit;
            return Act::Util::redirect(make_uri('main'))
        }
        else {
            my $template = Act::Template::HTML->new();
            $template->variables(
                end_date => DateTime::Format::Pg->parse_timestamp($Config->talks_end_date)->epoch,
            );
            $template->process('user/register');
            return;
        }
    }

    my $template = Act::Template::HTML->new();
    my $fields = {};
    my $duplicates = [];

    if ($Request{args}{join}) {         # registration form has been submitted

        # must have a valid twostep token
        (my $token) = Act::TwoStep::verify_form()
            or return;
            
        my @errors;

        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        if ($ok) {
            # create a user in memory only and find duplicates
            my $ghost = Act::User->new();
            $ghost->{$_} = $fields->{$_}
                for qw(login first_name last_name email country);
            $ghost->{user_id} = 0; # avoid undef
            $duplicates = $ghost->possible_duplicates();

            # check for existing user
            if (Act::User->new(login => $fields->{login})) {
                push @errors, 'ERR_IDENTIFIER_EXISTS';
                push @errors, 'ERR_DUPLICATE_EXISTS' if @$duplicates;
            }
            # check for duplicates
            elsif ( ! $fields->{ignore_duplicates} && @$duplicates ) {
                push @errors, 'ERR_DUPLICATE_EXISTS';
                $fields->{ignore_duplicates} = 1;
            }
            # create this user
            else {
            	# default timezone
            	$fields->{timezone} = $Config->general_timezone;

                # generate a random password
                my ($clear_passwd, $crypt_passwd) = Act::Util::gen_password();
                $fields->{passwd} = $crypt_passwd;

                # insert user in database
                # and participation to this conference
                my $user = Act::User->create(
                    %$fields,
                    participation => {
                        tshirt_size => $fields->{tshirt},
                        datetime    => DateTime::Format::Pg->format_timestamp_without_time_zone(DateTime->now()),
                        ip          => $Request{r}->connection->remote_ip,
                    },
                );

                # remove twostep token
                Act::TwoStep::remove($token);

                # log the user in
                Act::Util::login($user);

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
            $form->{invalid}{tshirt} && push @errors, 'ERR_TSHIRT';

        }
        $template->variables(errors => \@errors);
    }
    elsif ($Request{args}{twostepsubmit}) {      # two-step form has been submitted
        # validate form and create a new token
        if (Act::TwoStep::create(
                $twostep_template, $twostep_form,
                'user/twostep_add_email_subject', 'user/twostep_add_email_body',
                sub { $twostep_form->{fields}{email} },
                sub { my @errors;
                      $twostep_form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
                      $twostep_form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';
                      return \@errors;
                    },
        )) {
            $template->variables(email => $twostep_form->{fields}{email});
            $template->process('user/twostep_add_ok');
        }
        return;
    }
    else {
        # do we have a twostep token in the uri?
        Act::TwoStep::verify_uri($twostep_template)
            or return;
    }
    # display the registration form
    $template->variables(
        countries => Act::Country::CountryNames(),
        topten    => Act::Country::TopTen(),
        %$fields,
        duplicates => $duplicates,
        end_date => DateTime::Format::Pg->parse_timestamp($Config->talks_end_date)->epoch,
    );
    $template->process('user/add');
}

1;

=head1 NAME

Act::Handler::User::Register - create a new user

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
