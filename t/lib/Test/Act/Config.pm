package Test::Act::Config;
# ABSTRACT: Mock Act's configuration

use 5.020;
use Moo;
use Types::Standard qw(HashRef);

use Test::MockObject;

use Act::Config ();
my $orig_config = $Act::Config::Config;

use feature qw(signatures);
no warnings qw(experimental::signatures);

has values => (
    is => 'ro', isa => HashRef,
    default => sub { _use_test_database() },
);


sub _use_test_database {
    my %fields = ();
    for my $field (qw(database_dsn database_host
                      database_user database_passwd)) {
        my $mock_field = $field =~ s/database_/database_test_/r;
        $fields{$field} = $Act::Config::Config->$mock_field;
    }
    return \%fields;
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $field = $AUTOLOAD =~ s/.*:://r;
    return if $field eq 'DESTROY';
    if (defined (my $value = shift)) {
        $self->set($field => $value);
    }
    else {
        $self->get($field);
    }
}

sub get ($self,$key) {
    return $self->values->{$key} // $orig_config->$key;
}

sub set ($self,$key,$value) {
    $self->values->{$key} = $value;
}


1;

__END__

=encoding utf8

=head1 NAME

Test::Act::Config - Mock Act's configuration

=head1 SYNOPSIS

    use Act::Config ();
    use Test::Act::Config;
    $Act::Config::Config = Test::Act::Config->new;
    require Act::Module::Which::Needs::Mocked::Config # don't "use"!

=head1 DESCRIPTION

This class provides a default surrogate for Act's $Config hash.  Per
default, it picks up the connection attributes for the test database
and pulls all other configuration variables from the "real"
configuration.

=head1 ENVIRONMENT

=head1 FILES

The Act configuration files are evaluated as usual and left unchanged.

=head1 CAVEATS

Since the manipulation of the configuration happens at runtime, it
isn't effective for any modules which are "use"d at compile time.  So
either "require" them, or wrap the "use" into an eval block.

=head1 BUGS

=head1 RESTRICTIONS

Mocking other configuration variables isn't documented.

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
