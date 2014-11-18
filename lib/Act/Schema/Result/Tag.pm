use utf8;
package Act::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Tag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tags>

=cut

__PACKAGE__->table("tags");

=head1 ACCESSORS

=head2 tag_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tags_tag_id_seq'

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 tag

  data_type: 'text'
  is_nullable: 0

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 tagged_id

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tag_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tags_tag_id_seq",
  },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "tag",
  { data_type => "text", is_nullable => 0 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "tagged_id",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tag_id>

=back

=cut

__PACKAGE__->set_primary_key("tag_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YHSin+ZlT0bkntUYuvTNDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
