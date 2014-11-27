package Act::Schema::Result::Schema;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Schema

Holds the latest schema version as setup through L<Act::Database>.

=head1 TABLE: C<schema>

=cut

table "schema";

=head1 ACCESSORS

=head2 current_version

Holds the actual latest version of the Act Database Schema

=cut

column "current_version" => {
    data_type          => 'integer',
};

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
