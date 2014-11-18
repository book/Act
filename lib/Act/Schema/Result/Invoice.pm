use utf8;
package Act::Schema::Result::Invoice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Invoice

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<invoices>

=cut

__PACKAGE__->table("invoices");

=head1 ACCESSORS

=head2 invoice_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'invoices_invoice_id_seq'

=head2 order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 datetime

  data_type: 'timestamp'
  is_nullable: 0

=head2 invoice_no

  data_type: 'integer'
  is_nullable: 0

=head2 amount

  data_type: 'integer'
  is_nullable: 0

=head2 means

  data_type: 'text'
  is_nullable: 1

=head2 currency

  data_type: 'text'
  is_nullable: 1

=head2 first_name

  data_type: 'text'
  is_nullable: 1

=head2 last_name

  data_type: 'text'
  is_nullable: 1

=head2 company

  data_type: 'text'
  is_nullable: 1

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 vat

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "invoice_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "invoices_invoice_id_seq",
  },
  "order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "datetime",
  { data_type => "timestamp", is_nullable => 0 },
  "invoice_no",
  { data_type => "integer", is_nullable => 0 },
  "amount",
  { data_type => "integer", is_nullable => 0 },
  "means",
  { data_type => "text", is_nullable => 1 },
  "currency",
  { data_type => "text", is_nullable => 1 },
  "first_name",
  { data_type => "text", is_nullable => 1 },
  "last_name",
  { data_type => "text", is_nullable => 1 },
  "company",
  { data_type => "text", is_nullable => 1 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "vat",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</invoice_id>

=back

=cut

__PACKAGE__->set_primary_key("invoice_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<invoices_idx>

=over 4

=item * L</order_id>

=back

=cut

__PACKAGE__->add_unique_constraint("invoices_idx", ["order_id"]);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xtOcu1p5LCWYOspxl6tzXw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
