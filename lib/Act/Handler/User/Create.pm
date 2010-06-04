package Act::Handler::User::Create;
use strict;

use Apache::Constants qw(FORBIDDEN);
use Act::Config;
use Act::Country;
use Act::Form;
use Act::Template::HTML;
use Act::User;
use Act::Util;

# creation form
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
     tshirt => sub { $_[0] =~ /^(?:X?S|M|[456]?X{0,3}LT?)(?: \(W\))?$/ },
  }
);

# registration form
my $register_form = Act::Form->new(
    required => [qw( user_id )],
);

sub handler
{
    # only orgas can run this
    unless ( $Request{user}->is_users_admin ) {
        $Request{status} = FORBIDDEN;
        return;
    }

    my @errors;
    my $template = Act::Template::HTML->new();
    my $fields = {};
    my $duplicates = [];

    #
    # create form
    #
    if ($Request{args}{join}) {

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
    }
    #
    # register form
    #
    elsif ($Request{args}{register}) {

        # check that the user_id exist
        my $ok = $register_form->validate($Request{args});
        my $fields = $register_form->{fields};

        if ($ok && ( my $user = Act::User->new(user_id => $fields->{user_id}) )) {

            # create a new participation to this conference
            if( ! defined $user->participation ) {
                my $sth = $Request{dbh}->prepare_cached(
                    "INSERT INTO participations (user_id, conf_id) VALUES (?,?);"
                );
                $sth->execute($user->user_id, $Request{conference});
                $sth->finish();
                $Request{dbh}->commit;
            }
            return Act::Util::redirect(make_uri_info('user', $user->user_id))
        }
        else {
            push @errors, 'ERR_USERID';
        }
    }

    # display the registration form
    $template->variables(
        countries => Act::Country::CountryNames(),
        topten    => Act::Country::TopTen(),
        %$fields,
        duplicates => $duplicates,
        errors     => \@errors,
    );
    $template->process('user/create');
}

1;

=head1 NAME

Act::Handler::User::Register - create a new user

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
