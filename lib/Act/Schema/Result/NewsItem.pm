package Act::Schema::Result::NewsItem;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::NewsItem

=head1 DESCRIPTION

A 'per language' translation for the L<Act::Schema::Result::News> entry.

=head1 TABLE: C<news_items>

=cut

table "news_items";

=head1 ACCESSORS

=head2 news_item_id

Primary Key for language specific translations for News publications

=cut

column "news_item_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    sequence           => 'news_items_news_item_id_seq',
};

=head2 news_id

L<Act::Schema::Result::News> ID

=cut

column "news_id" => {
    data_type          => 'integer',
};

=head2 lang

ISO language identifier

=cut

column "lang" => {
    data_type          => 'text',
};

=head2 title

Language specific title for the News publication

=cut

column "title" => {
    data_type          => 'text',
};

=head2 text

Language specific text for the News publication

=cut

column "text" => {
    data_type          => 'text',
};

=head1 PRIMARY KEY

=over 4

=item * L</news_item_id>

=back

=cut

primary_key "news_item_id";

=head1 UNIQUE CONSTRAINTS

=head2 C<news_items_news_id_key>

=over 4

=item * L</news_id>

=item * L</lang>

=back

=cut

unique_constraint "news_items_news_id_key" => ["news_id", "lang"];

=head1 RELATIONS

=head2 news

belongs_to L<Act::Schema::Result::News>

=cut

belongs_to "news" => "Act::Schema::Result::News",
    { news_id => "news_id" },
    {},
;

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
