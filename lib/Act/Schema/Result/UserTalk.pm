use utf8;
package Act::Schema::Result::UserTalk;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::UserTalk

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_talks>

=cut

__PACKAGE__->table("user_talks");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 talk_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "talk_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 RELATIONS

=head2 talk

Type: belongs_to

Related object: L<Act::Schema::Result::Talk>

=cut

__PACKAGE__->belongs_to(
  "talk",
  "Act::Schema::Result::Talk",
  { talk_id => "talk_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MpBxKgOMBH7EzdX4K38k8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
