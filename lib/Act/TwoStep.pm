package Act::TwoStep;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Digest::MD5;

use Act::Config;
use Act::Email;
use Act::Template;
use Act::Template::HTML;
use Act::Util;

# returns true if token is present in pathinfo and exists in database
# otherwise displays the twostep form and returns undef
sub verify_uri
{
    my $template_file = shift;

    # do we have an authentication token in the uri?
    my $token = $Request{path_info};
    if ($token) {
        # yes, see if it exists in the database
        unless (_exists($token)) {
            # invalid token
            $Request{status} = NOT_FOUND;
            return;
        }
        # valid auth token
        return 1;
    }
    # no token: display email address form
    _display_form($template_file);
    return;
}

# validate twostep form and create a new token
sub create
{
    my ($template_file, $form, $email_subject_file, $email_body_file, $email_get, $errors_get, $data_get) = @_;
    my $ok = $form->validate($Request{args});
    if ($ok) {
        my $email = $email_get->();

        # create a new token
        my $token = _create_token($email);
        
        # store it in the database
        my $data;
        $data = $data_get->() if $data_get;
        my $sth = $Request{dbh}->prepare_cached('INSERT INTO twostep (token, email, datetime, data) VALUES (?, ?, NOW(), ?)');
        $sth->execute($token, $email, $data);
        $Request{dbh}->commit;

        # email it
        _send_email($email_subject_file, $email_body_file, $token, $email);

        # return success
        return 1;
    }
    else {
        # map errors
        my $errors = $errors_get->();

        # display form again
        _display_form($template_file, $errors, $form->{fields});
        
        # return error
        return 0;
    }
}

# verify that submitted form contains valid token
sub verify_form
{
    # do we have an authentication token in the uri?
    my $token = $Request{path_info};
    if ($token) {
        my $data = _exists($token);
        return ($token, $$data) if $data;
    }
    $Request{status} = FORBIDDEN;
    return;
}

# remove token
sub remove
{
    my $token = shift;

    my $sth = $Request{dbh}->prepare_cached('DELETE FROM twostep WHERE token = ?');
    $sth->execute($token);
    $Request{dbh}->commit;
}

# display the twostep form
sub _display_form
{
    my ($template_file, $errors, $fields) = @_;

    my $template = Act::Template::HTML->new();
    $template->variables(errors => $errors) if $errors;
    $template->variables(%$fields) if $fields;
    $template->process($template_file);
}

# returns twostep data if token exists in database
sub _exists
{
    my $token = shift;

    my $sth = $Request{dbh}->prepare_cached('SELECT token, data FROM twostep WHERE token = ?');
    $sth->execute($token);
    my ($found, $data) = $sth->fetchrow_array();
    $sth->finish;
    return $found ? \$data : undef;
}

# create a new token
sub _create_token
{
    my $email = shift;

    my $digest = Digest::MD5->new;
    $digest->add(rand(9999), time(), $$, $email);
    my $token = $digest->md5_hex();
    $token =~ s/\W/-/g;
    return $token;
}

# send email with link embedding token
sub _send_email
{
    my ($email_subject_file, $email_body_file, $token, $email) = @_;

    # generate subject and body from templates
    my $template = Act::Template->new;
    my $subject;
    $template->process($email_subject_file, \$subject);
    chomp $subject;

    my $body;
    $template->variables(
        email => $email,
        token => $token,
        link  => $Request{base_url} . join('/', self_uri(), $token),
    );
    $template->process($email_body_file, \$body);

    # send the email
    Act::Email::send(
        from    => $Config->email_sender_address,
        to      => $email,
        subject => $subject,
        body    => $body,
    );
}

1;

__END__

=head1 NAME

Act::TwoStep - Two-step handler utility routines

=head1 SYNOPSIS

Modify an existing form handler to work in two steps:

    # twostep form
    my $twostep_form = Act::Form->new(
      required    => [qw(email)],
      filters     => { email => sub { lc shift } },
      constraints => { email => 'email' },
    );
    # twostep template filename
    my $twostep_template = 'user/twostep_add';
    
    ...
    
    if ($Request{args}{ok}) {                   # form has been submitted
        # must have a valid twostep token
        my ($token, $token_data) = Act::TwoStep::verify_form()
            or return;
        ...
        # if form is valid, remove token
        my $ok = $form->validate($Request{args});
        if ($ok) {
            ...
            Act::TwoStep::remove($token);
        }
        ...
    }
    elsif ($Request{args}{twostepsubmit}) {     # two-step form has been submitted
        # validate form and create a new token
        if (Act::TwoStep::create(
           $twostep_template, $twostep_form,
           $twostep_email_subject_template, $twostep_email_body_template,
                sub { $twostep_form->{fields}{email} },
                sub { my @errors;
                      $twostep_form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
                      $twostep_form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';
                      return \@errors;
                    },
                sub { $token_data },
        )) {
            # twostep form is valid, display confirmation page
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
    # display form
    $template->process(...);


=head1 DESCRIPTION

Act::TwoStep contains a collection of utility routines to assist in creating
two-step handlers. A two-step handler sends an email to the user with a link
back to the handler. The link embeds an authentication token.

=over 4

=item $token = verify_uri($twostep_template)

Returns token if present in pathinfo and exists in database,
otherwise displays a form using the supplied $twostep_template and returns undef.

Your handler should return after calling this function if it returns undef;

=item ($token, $token_data) = verify_form()

Returns token and optional token data if present in submitted form data and exists in database,
otherwise sets the handler return status to FORBIDDEN and returns undef,

Your handler should return after calling this function if it returns undef.

=item create($twostep_template_file, $twostep_form, $email_subject_file, $email_body_file, $email_get, $errors_get, $toen_data_get)

Validates the submitted twostep form, creates a new token in the database,
and sends an email back to the user with a link embedding the token,
and displays an acknowledgement page.
$token_data is an optional sub that returns data that will later be retrived with C<verify_form()>.

Your handler should return after calling this function.

=item remove($token)

Removes the token from the database. Your handler should call this function
when its form has been submitted and is valid.

=back

=cut
