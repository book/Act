use utf8;
package Act::Schema::Result::Right;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Right

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<rights>

=cut

__PACKAGE__->table("rights");

=head1 ACCESSORS

=head2 right_id

  data_type: 'text'
  is_nullable: 0

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "right_id",
  { data_type => "text", is_nullable => 0 },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Act::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Act::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c8e7i7sslaxyNP4y9A9wjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
