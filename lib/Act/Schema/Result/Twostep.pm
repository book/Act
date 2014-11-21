package Act::Schema::Result::Twostep;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::Twostep

=head1 DESCRIPTION

TODO:

=head1 TABLE: C<twostep>

=cut

table "twostep";

=head1 ACCESSORS

=head2 token

TODO:

=cut
column "token" => {
    data_type          => 'char',
    is_nullable        => 0,
    size               => 32,
};

=head2 email

TODO:

=cut

column "email" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 datetime

TODO:

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 1,
};

=head2 data

TODO:

=cut

column "data" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</token>

=back

=cut

primary_key "token";

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
