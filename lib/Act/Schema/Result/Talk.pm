use utf8;
package Act::Schema::Result::Talk;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Talk

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<talks>

=cut

__PACKAGE__->table("talks");

=head1 ACCESSORS

=head2 talk_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'talks_talk_id_seq'

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 url_abstract

  data_type: 'text'
  is_nullable: 1

=head2 url_talk

  data_type: 'text'
  is_nullable: 1

=head2 duration

  data_type: 'integer'
  is_nullable: 1

=head2 lightning

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 accepted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 confirmed

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 room

  data_type: 'text'
  is_nullable: 1

=head2 datetime

  data_type: 'timestamp'
  is_nullable: 1

=head2 track_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 level

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 lang

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "talk_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "talks_talk_id_seq",
  },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "url_abstract",
  { data_type => "text", is_nullable => 1 },
  "url_talk",
  { data_type => "text", is_nullable => 1 },
  "duration",
  { data_type => "integer", is_nullable => 1 },
  "lightning",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "accepted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "confirmed",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "room",
  { data_type => "text", is_nullable => 1 },
  "datetime",
  { data_type => "timestamp", is_nullable => 1 },
  "track_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "level",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "lang",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</talk_id>

=back

=cut

__PACKAGE__->set_primary_key("talk_id");

=head1 RELATIONS

=head2 track

Type: belongs_to

Related object: L<Act::Schema::Result::Track>

=cut

__PACKAGE__->belongs_to(
  "track",
  "Act::Schema::Result::Track",
  { track_id => "track_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 user

Type: belongs_to

Related object: L<Act::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Act::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user_talks

Type: has_many

Related object: L<Act::Schema::Result::UserTalk>

=cut

__PACKAGE__->has_many(
  "user_talks",
  "Act::Schema::Result::UserTalk",
  { "foreign.talk_id" => "self.talk_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b+inVQY0R59GkJ4I4VnvwQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
