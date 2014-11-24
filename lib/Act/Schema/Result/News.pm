package Act::Schema::Result::News;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::News

=head1 DESCRIPTION

News Entries index, which can have per language translated L<Act::Schema::Result::NewsItem>s

=head1 TABLE: C<news>

=cut

table "news";

=head1 ACCESSORS

=head2 news_id

Primary key, News ID

=cut

column "news_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'news_news_id_seq',
};

=head2 conf_id

Cummunity Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 datetime

Date and Time of this News publication.

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 0,
};

=head2 user_id

User ID of the author of this News publication

=cut

column "user_id" => {
    data_type          => 'integer',
    is_nullable        => 0,
};

=head2 published

Flag to indicate wether or not a News article is already published or not.

=cut

column "published" => {
    data_type          => 'boolean',
    default_value      => \"false",
    is_nullable        => 0,
};

=head1 PRIMARY KEY

=over 4

=item * L</news_id>

=back

=cut

primary_key "news_id";

=head1 RELATIONS

=head2 news_items

has_many L<Act::Schema::Result::NewsItem>s.

=cut

has_many "news_items" => "Act::Schema::Result::NewsItem",
    { "foreign.news_id" => "self.news_id" },
    { cascade_copy => 0, cascade_delete => 0 };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
