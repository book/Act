package Act::Schema::Result::Login;
# ABSTRACT: Act User's login data

use base qw/DBIx::Class::Core/;
__PACKAGE__->table('logins');
my %columns = (
    login =>  { data_type => 'text',
                is_nullable => 0,
              },
    passwd => { data_type => 'text',
                is_nullable => 0,
              },
);
__PACKAGE__->add_columns(%columns);


1;

__END__

=encoding utf8

=head1 NAME

Act::Schema::Result::Login -  Act User's login data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 FILES

=head1 CAVEATS

=head1 BUGS

=head1 RESTRICTIONS

=head1 NOTES

=head1 AUTHOR

Harald Jörg, haj@posteo.de

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Harald Jörg

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
