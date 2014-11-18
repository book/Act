use utf8;
package Act::Schema::Result::PmGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::PmGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pm_groups>

=cut

__PACKAGE__->table("pm_groups");

=head1 ACCESSORS

=head2 group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pm_groups_group_id_seq'

=head2 xml_group_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'text'
  is_nullable: 1

=head2 continent

  data_type: 'text'
  is_nullable: 1

=head2 country

  data_type: 'text'
  is_nullable: 1

=head2 state

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pm_groups_group_id_seq",
  },
  "xml_group_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "text", is_nullable => 1 },
  "continent",
  { data_type => "text", is_nullable => 1 },
  "country",
  { data_type => "text", is_nullable => 1 },
  "state",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</group_id>

=back

=cut

__PACKAGE__->set_primary_key("group_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xyZA/nwtEchoZnftpx/klg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
