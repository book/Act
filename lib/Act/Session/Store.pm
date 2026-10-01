package Act::Session::Store;
# ABSTRACT: A Plack::Session::Store using Act's Database

use parent 'Plack::Session::Store::DBI';
use Act::Store::Database;

sub new {
    my $class = shift;
    my $base = $class->SUPER::new(
        get_dbh => sub { Act::Store::Database->instance->connector->dbh },
    );
}

1;

__END__

=encoding utf8

=head1 NAME

Act::Session::Store -  A Plack::Session::Store using Act's Database

=head1 SYNOPSIS

    my $app            = builder {
        enable 'Session',
            # ... Plack::Session stuff here
            store       => Act::Session::Store->new(),
            ;
        mount "/" => \&my_app;
    };


=head1 DESCRIPTION

This module is a thin wrapper around Plack::Session::Store::DBI, using
Act's database as a storage backend.  This module allows for easy
testing without a database connection by mocking the new() method to
use the default in-memory store.

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
