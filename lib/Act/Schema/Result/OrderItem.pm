use utf8;
package Act::Schema::Result::OrderItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::OrderItem

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<order_items>

=cut

__PACKAGE__->table("order_items");

=head1 ACCESSORS

=head2 item_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'order_items_item_id_seq'

=head2 order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 amount

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 registration

  data_type: 'boolean'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "item_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "order_items_item_id_seq",
  },
  "order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "amount",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "registration",
  { data_type => "boolean", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=back

=cut

__PACKAGE__->set_primary_key("item_id");

=head1 RELATIONS

=head2 order

Type: belongs_to

Related object: L<Act::Schema::Result::Order>

=cut

__PACKAGE__->belongs_to(
  "order",
  "Act::Schema::Result::Order",
  { order_id => "order_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ccgJAB88d9TUt2vIfCUe7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
