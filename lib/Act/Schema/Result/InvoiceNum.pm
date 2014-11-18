package Act::Schema::Result::InvoiceNum;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::InvoiceNum

=head1 DESCRIPTION

Helps to keep track of the invoices per Community Event

=head1 TABLE: C<invoice_num>

=cut

table "invoice_num";

=head1 ACCESSORS

=head2 conf_id

Cummunity Event ID.

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 next_num

Invoice sequence number per Cumminity Event.

=cut

column "next_num" => {
    data_type          => 'integer',
    is_nullable        => 0,
};

=head1 PRIMARY KEY

=over 4

=item * L</conf_id>

=back

=cut

primary_key "conf_id";

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
