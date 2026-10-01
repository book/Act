use utf8;
package Act::Schema::Result::InvoiceNum;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::InvoiceNum

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<invoice_num>

=cut

__PACKAGE__->table("invoice_num");

=head1 ACCESSORS

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 next_num

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "next_num",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</conf_id>

=back

=cut

__PACKAGE__->set_primary_key("conf_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-07-31 16:42:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CeVXFpw4HwiwxP4aLc+mkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
