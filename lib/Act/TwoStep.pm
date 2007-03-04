package Act::TwoStep;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Digest::MD5;

use Act::Config;
use Act::Email;
use Act::Form;
use Act::Template;
use Act::Template::HTML;
use Act::Util;

my $form = Act::Form->new(
  required    => [qw(email)],
  filters     => { email => sub { lc shift } },
  constraints => { email => 'email' },
);

# returns token if present in pathinfo and exists in database
# otherwise displays the form and returns undef
sub verify_uri
{
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
        return $token;
    }
    # no token: display email address form
    _display_form();
    return;
}

# validate form and create a new token
sub create
{
    my $ok = $form->validate($Request{args});
    if ($ok) {
        my $email = $Request{args}{email};

        # create a new token
        my $token = _create_token($email);
        
        # store it in the database
        my $sth = $Request{dbh}->prepare_cached('INSERT INTO twostep (token, email, datetime) VALUES (?, ?, NOW())');
        $sth->execute($token, $Request{args}{email});
        $Request{dbh}->commit;

        # email it
        _send_email($token, $email);

        # thanks, user
        my $template = Act::Template::HTML->new();
        $template->variables(email => $email);
        $template->process('twostep/ok');
    }
    else {
        # map errors
        my @errors;
        $form->{invalid}{email} eq 'required' && push @errors, 'ERR_EMAIL';
        $form->{invalid}{email} eq 'email'    && push @errors, 'ERR_EMAIL_SYNTAX';

        # display form again
        _display_form(\@errors, $form->{fields});
    }
}

# verify that submitted form contains valid token
sub verify_form
{
    # do we have an authentication token in the uri?
    my $token = $Request{path_info};
    return $token if $token && _exists($token);
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

# display the email address form
sub _display_form
{
    my ($errors, $fields) = @_;

    my $template = Act::Template::HTML->new();
    $template->variables(errors => $errors) if $errors;
    $template->variables(%$fields) if $fields;
    $template->process('twostep/form');
}

# returns true if token exists in database
sub _exists
{
    my $token = shift;

    my $sth = $Request{dbh}->prepare_cached('SELECT token FROM twostep WHERE token = ?');
    $sth->execute($token);
    (my $found) = $sth->fetchrow_array();
    $sth->finish;
    return $found;
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
    my ($token, $email) = @_;

    # generate subject and body from templates
    my $template = Act::Template->new;
    my $subject;
    $template->process("core/twostep/email_subject", \$subject);
    chomp $subject;

    my $body;
    $template->variables(
        email => $email,
        token => $token,
        link  => $Request{base_url} . join('/', self_uri(), $token),
    );
    $template->process("core/twostep/email_body", \$body);

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

    my $token;
    if ($Request{args}{ok}) {                   # form has been submitted
        # must have a valid twostep token
        $token = Act::TwoStep::verify_form()
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
        Act::TwoStep::create();
        return;
    }
    else {
        # do we have a twostep token in the uri?
        $token = Act::TwoStep::verify_uri();
            or return;
    }
    # display form
    $template->process(...);


=head1 DESCRIPTION

Act::TwoStep contains a collection of utility routines to assist in creating
two-step handlers. A two-step handler sends an email to the user with a link
back to the handler. The link embeds an authentication token.

=over 4

=item $token = verify_uri()

Returns token if present in pathinfo and exists in database,
otherwise displays a form with an email address field and returns undef.

Your handler should return after calling this function if it returns undef;

=item $token = verify_form()

Returns token if present in submitted form data and exists in database,
otherwise sets the handler return status to FORBIDDEN and returns undef,

Your handler should return after calling this function if it returns undef;

=item create()

Validates the submitted email address, creates a new token in the database,
and sends an email back to the user with a link embedding the token,
and displays an acknowledgement page.

Your handler should return after calling this function.

=item remove($token)

Removes the token from the database. Your handler should call this function
when its form has been submitted and is valid.

=back

=cut
