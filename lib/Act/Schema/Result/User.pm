use utf8;
package Act::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'users_user_id_seq'

=head2 login

  data_type: 'text'
  is_nullable: 0

=head2 passwd

  data_type: 'text'
  is_nullable: 0

=head2 session_id

  data_type: 'text'
  is_nullable: 1

=head2 salutation

  data_type: 'integer'
  is_nullable: 1

=head2 first_name

  data_type: 'text'
  is_nullable: 1

=head2 last_name

  data_type: 'text'
  is_nullable: 1

=head2 nick_name

  data_type: 'text'
  is_nullable: 1

=head2 pseudonymous

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 country

  data_type: 'text'
  is_nullable: 0

=head2 town

  data_type: 'text'
  is_nullable: 1

=head2 web_page

  data_type: 'text'
  is_nullable: 1

=head2 pm_group

  data_type: 'text'
  is_nullable: 1

=head2 pm_group_url

  data_type: 'text'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 email_hide

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 gpg_key_id

  data_type: 'text'
  is_nullable: 1

=head2 pause_id

  data_type: 'text'
  is_nullable: 1

=head2 monk_id

  data_type: 'text'
  is_nullable: 1

=head2 monk_name

  data_type: 'text'
  is_nullable: 1

=head2 im

  data_type: 'text'
  is_nullable: 1

=head2 photo_name

  data_type: 'text'
  is_nullable: 1

=head2 language

  data_type: 'text'
  is_nullable: 1

=head2 timezone

  data_type: 'text'
  is_nullable: 0

=head2 company

  data_type: 'text'
  is_nullable: 1

=head2 company_url

  data_type: 'text'
  is_nullable: 1

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 vat

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_user_id_seq",
  },
  "login",
  { data_type => "text", is_nullable => 0 },
  "passwd",
  { data_type => "text", is_nullable => 0 },
  "session_id",
  { data_type => "text", is_nullable => 1 },
  "salutation",
  { data_type => "integer", is_nullable => 1 },
  "first_name",
  { data_type => "text", is_nullable => 1 },
  "last_name",
  { data_type => "text", is_nullable => 1 },
  "nick_name",
  { data_type => "text", is_nullable => 1 },
  "pseudonymous",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "country",
  { data_type => "text", is_nullable => 0 },
  "town",
  { data_type => "text", is_nullable => 1 },
  "web_page",
  { data_type => "text", is_nullable => 1 },
  "pm_group",
  { data_type => "text", is_nullable => 1 },
  "pm_group_url",
  { data_type => "text", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "email_hide",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "gpg_key_id",
  { data_type => "text", is_nullable => 1 },
  "pause_id",
  { data_type => "text", is_nullable => 1 },
  "monk_id",
  { data_type => "text", is_nullable => 1 },
  "monk_name",
  { data_type => "text", is_nullable => 1 },
  "im",
  { data_type => "text", is_nullable => 1 },
  "photo_name",
  { data_type => "text", is_nullable => 1 },
  "language",
  { data_type => "text", is_nullable => 1 },
  "timezone",
  { data_type => "text", is_nullable => 0 },
  "company",
  { data_type => "text", is_nullable => 1 },
  "company_url",
  { data_type => "text", is_nullable => 1 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "vat",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<users_login>

=over 4

=item * L</login>

=back

=cut

__PACKAGE__->add_unique_constraint("users_login", ["login"]);

=head2 C<users_session_id>

=over 4

=item * L</session_id>

=back

=cut

__PACKAGE__->add_unique_constraint("users_session_id", ["session_id"]);

=head1 RELATIONS

=head2 orders

Type: has_many

Related object: L<Act::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "Act::Schema::Result::Order",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 participations

Type: has_many

Related object: L<Act::Schema::Result::Participation>

=cut

__PACKAGE__->has_many(
  "participations",
  "Act::Schema::Result::Participation",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rights

Type: has_many

Related object: L<Act::Schema::Result::Right>

=cut

__PACKAGE__->has_many(
  "rights",
  "Act::Schema::Result::Right",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 talks

Type: has_many

Related object: L<Act::Schema::Result::Talk>

=cut

__PACKAGE__->has_many(
  "talks",
  "Act::Schema::Result::Talk",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_talks

Type: has_many

Related object: L<Act::Schema::Result::UserTalk>

=cut

__PACKAGE__->has_many(
  "user_talks",
  "Act::Schema::Result::UserTalk",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bMLIN8msVToziWBS9aaCYg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
