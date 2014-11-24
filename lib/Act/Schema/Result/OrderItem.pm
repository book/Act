package Act::Schema::Result::OrderItem;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::OrderItem

=head1 DESCRIPTION

Each specific Item for a L<Act::Schema::Result::Order>

=head1 TABLE: C<order_items>

=cut

table "order_items";

=head1 ACCESSORS

=head2 item_id

Primary Key for L<Act::Schema::Result::OrderItem>s

=cut

column "item_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'order_items_item_id_seq',
};

=head2 order_id

Foreign Key for L<Act::Schema::Result::Order>

=cut

column "order_id" => {
    data_type          => 'integer',
    is_foreign_key     => 1,
    is_nullable        => 0,
};

=head2 amount

Amount for this specific Order Item

=cut

column "amount" => {
    data_type          => 'integer',
    is_nullable        => 0,
};

=head2 name

Short description of the specific Order Item

=cut

column "name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 registration

Registration flag that indicates if this Order Item will be treated as a
"confirmed" registration.

=cut

column "registration" => {
    data_type          => 'boolean',
    is_nullable        => 0,
};


=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=back

=cut

primary_key "item_id";

=head1 RELATIONS

=head2 order

belongs_to ~elated object: L<Act::Schema::Result::Order>

=cut

belongs_to "order" => "Act::Schema::Result::Order",
    { order_id => "order_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
