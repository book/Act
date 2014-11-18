package Act::Schema::Result::Bio;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::Bio

=head1 DESCRIPTION

Act allows users to have their bio's in as much languages as they self like to
provide. These are shared among all community events.

=head1 TABLE: C<bios>

=cut

table "bios";

=head1 ACCESSORS

=head2 user_id

=cut

column user_id => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 lang

Language identifier as definend in ....

=cut

column lang => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 bio

Descriptive text for a specific language.

=cut

column bio => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 UNIQUE CONSTRAINTS

=head2 C<bios_idx>

=over 4

=item * L</user_id>

=item * L</lang>

=back

=cut

unique_constraint "bios_idx" => ["user_id", "lang"];

=head1 RELATIONS

=for improvements head2 user
 
belongs_to L<Act::Schema::Result::User>
 
=cut

# belongs_to "user" => "Act::Schema::Result::User",
#     { user_id => "user_id" },
#     { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
