package Act::Schema::Result::Order;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::Order

=head1 DESCRIPTION

A collection of L<Act::Schema::Result::OrderItem>s, as attendees can oder more
than just simple a admission fee. Invoices have their own tables.

=head1 TABLE: C<orders>

=cut

table "orders";

=head1 ACCESSORS

=head2 order_id

Primary Key ID

=cut

column "order_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'orders_order_id_seq',
};

=head2 conf_id

Cummunity Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 user_id

User ID of the author of this News publication

=cut

column "user_id" => {
    data_type          => 'integer',
    is_foreign_key     => 1,
    is_nullable        => 0,
};

=head2 datetime

Date and time when the Invoice has been created.

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 0,
};

=head2 means

Payment Methode

=cut

column "means" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 currency

The currency in which the invoice has been made, ussualy defined in the config.

=cut

column "currency" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 status

Status

=cut

column "status" => {
    data_type          => 'text',
    is_nullable        => 0,
}; 

=head2 type

Type

=cut

column "type" => {
    data_type          => 'text',
    is_nullable        => 1,
}

=cut

=head1 PRIMARY KEY

=over 4

=item * L</order_id>

=back

=cut

primary_key "order_id";

=head1 RELATIONS

=head2 invoice

might_have related object: L<Act::Schema::Result::Invoice>

=cut

might_have "invoice" => "Act::Schema::Result::Invoice",
  { "foreign.order_id" => "self.order_id" },
  { cascade_copy => 0, cascade_delete => 0 };

=head2 order_items

has_many related object: L<Act::Schema::Result::OrderItem>

=cut

has_many "order_items" => "Act::Schema::Result::OrderItem",
  { "foreign.order_id" => "self.order_id" },
  { cascade_copy => 0, cascade_delete => 0 };

=head2 user

belongs_to related object: L<Act::Schema::Result::User>

=cut

belongs_to "user" => "Act::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
