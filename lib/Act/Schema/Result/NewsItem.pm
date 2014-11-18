use utf8;
package Act::Schema::Result::NewsItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::NewsItem

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<news_items>

=cut

__PACKAGE__->table("news_items");

=head1 ACCESSORS

=head2 news_item_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'news_items_news_item_id_seq'

=head2 news_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 lang

  data_type: 'text'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 text

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "news_item_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "news_items_news_item_id_seq",
  },
  "news_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "lang",
  { data_type => "text", is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "text",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</news_item_id>

=back

=cut

__PACKAGE__->set_primary_key("news_item_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<news_items_news_id_key>

=over 4

=item * L</news_id>

=item * L</lang>

=back

=cut

__PACKAGE__->add_unique_constraint("news_items_news_id_key", ["news_id", "lang"]);

=head1 RELATIONS

=head2 news

Type: belongs_to

Related object: L<Act::Schema::Result::News>

=cut

__PACKAGE__->belongs_to(
  "news",
  "Act::Schema::Result::News",
  { news_id => "news_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wpQ7gOuilW4YYg0JqSEq+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
