package Act::Auth::Password;
# ABSTRACT: Manage password authentication for Act users

use 5.020;

use Act::Store::Database;

use Authen::Passphrase::BlowfishCrypt;
use Authen::Passphrase;
use Digest::SHA qw(sha512);
use Digest::MD5;
use Encode qw(encode);
use Try::Tiny;

use feature qw(signatures);
no warnings qw(experimental::signatures);

my $resultset = Act::Store::Database->instance->schema->resultset('User');

# ----------------------------------------------------------------------

=head1 METHODS

=head2 Class Method set_password

Encrypts the password given for the login name and writes it to the store.

=cut

sub set_password ($,$login,$password) {
    my $user = $resultset->find( { login => $login } );
    $user->passwd(_crypt_password($password));
    $user->update;
}

sub _crypt_password {
    my ($pass) = @_;

    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
        cost        => 8,
        salt_random => 1,
        passphrase  => _sha_pass($pass),
    );
    return $ppr->as_rfc2307;
}

sub _sha_pass ($pass) {
    return sha512(encode('UTF-8',$pass,Encode::FB_CROAK));
}

# ----------------------------------------------------------------------

=head2 check_password ($login,$password)

This method takes a login name and a plaintext password and checks
them against the user database.

If the user database contains a legacy, MD5 hashed password, it uses
the plaintext password to update the user's entry in the database to
the current password protection schema
L<Authen::Passphrase::BlowfishCrypt>.

In case of a bad login the method dies.

This method does I<not> user authorization, this has to be done by the
caller.  In case of a new user registration, or a password reset
operation, the sessions are not authenticatied, but the request is
protected with an one-time token.

=cut

sub check_password ($,$login,$password) {
    my $user = $resultset->find( { login => $login } )
        or die "Unknown user";
    my $pw_hash = $user->passwd;
    my $ppr = eval { Authen::Passphrase->from_rfc2307($pw_hash); };
    return 1 if $ppr && $ppr->match(_sha_pass($password));
    return 1 if _check_legacy_password($login,$password,$pw_hash);
    die 'Bad password';
}

sub _check_legacy_password {
    my ($login,$check_pass,$pw_hash) = @_;
    my ($scheme, $hash) = $pw_hash =~ /^(?:{(\w+)})?(.*)$/;

    if (!$scheme || $scheme eq 'MD5') {
        my $ok = try {
            my $digest = Digest::MD5->new;
            $digest->add($check_pass); # this dies from wide characters
            $digest->b64digest eq $hash;
        } catch {
            0; # a failed digest can be safely mapped to "bad password"
        };
        # upgrade hash
        $ok && Act::Auth::Password->set_password($login,$check_pass);
        return $ok;
    }
    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Act::Auth::Password -  Manage password authentication for Act users

=head1 SYNOPSIS

    Act::Auth::Password->set_password($login,$secret);
    # later...
    Act::Auth::Password->check_password($login,$secret);

=head1 DESCRIPTION

This module handles Act's password authentication: It writes user
password properly salted and encrypted to the database, and can check
them later.

=head1 DIAGNOSTICS

In case of errors, the subrouties in this module die and provide the
caller with an appropriate error information.

=head1 NOTES

Parts of this module have been moved from L<Act::User> and
L<Act::Middleware::Auth>.

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
