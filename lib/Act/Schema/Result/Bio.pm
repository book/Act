use utf8;
package Act::Schema::Result::Bio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Bio

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<bios>

=cut

__PACKAGE__->table("bios");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 lang

  data_type: 'text'
  is_nullable: 1

=head2 bio

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "lang",
  { data_type => "text", is_nullable => 1 },
  "bio",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<bios_idx>

=over 4

=item * L</user_id>

=item * L</lang>

=back

=cut

__PACKAGE__->add_unique_constraint("bios_idx", ["user_id", "lang"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JIXk+QL4y0RFU15pjqrBtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
