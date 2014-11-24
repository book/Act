package Act::Schema::Result::Tag;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Tag

=head1 TABLE: C<tags>

=cut

table "tags";

=head1 ACCESSORS

=head2 tag_id

Primary Key

=cut

column "tag_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'tags_tag_id_seq',
};

=head2 conf_id

Community Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 tag

TODO:

=cut

column "tag" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 type

TODO:

=cut

column "type" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 tagged_id

TODO:

=cut

column "tagged_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head1 PRIMARY KEY

=over 4

=item * L</tag_id>

=back

=cut

primary_key "tag_id";

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
