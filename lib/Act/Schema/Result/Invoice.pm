package Act::Schema::Result::Invoice;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::Invoice

=head1 DESCRIPTION

...

=cut

=head1 TABLE: C<invoices>

=cut

table "invoices";

=head1 ACCESSORS

=head2 invoice_id

Primary Key

=cut

column "invoice_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'invoices_invoice_id_seq',
};

=head2 order_id

The ID of the L<Act::Schema::Result::Order>. Note, not every order has an
Invoice.

=cut

column "order_id" => {
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

=head2 invoice_no

Invoice numbers come from L<Act::Schema::Result::InvoiceNum> and are Community
Event specific.

=cut

column "invoice_no" => {
    data_type          => 'integer',
    is_nullable        => 0,
};

=head2 amount

The amount being paid

=cut

column "amount" => {
      data_type        => 'integer',
      is_nullable      => 0,
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

=head2 first_name

First Name of the attendee.

=cut

column "first_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 last_name

Last Name of the attendee.

=cut

column "last_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 company

Company Name.

=cut

column "company" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 address

Address to where the Invoice should be sent to (if it would be sent).

=cut

column "address" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 vat

=cut
column "vat" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</invoice_id>

=back

=cut

primary_key "invoice_id";

=head1 UNIQUE CONSTRAINTS

=head2 C<invoices_idx>

=over 4

=item * L</order_id>

=back

=cut

unique_constraint "invoices_idx" => ["order_id"];

=head1 RELATIONS

=head2 order

belongs_to L<Act::Schema::Result::Order>

=cut

belongs_to "order" => "Act::Schema::Result::Order",
  { order_id => "order_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
