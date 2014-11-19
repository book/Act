package Act::Schema::Result::Right;
use utf8;
use 'Act::Schema::Candy';

=head1 NAME

Act::Schema::Result::Right

Defines what privileges a user has for a specific Cummunity Event

=head1 TABLE: C<rights>

=cut

table "rights";

=head1 ACCESSORS

=head2 right_id

A 'Privilege' as described in the manuals, currently there are: 'admin',
'talks_admin', 'users_admin', 'news_admin', 'wiki_admin' and 'treasurer'.

=cut

column "right_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 conf_id

Cumminity Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 user_id

Foreign Key for L<Act::Schema::Result::User>

=cut

column "user_id" => {
    data_type          => 'integer',
    is_foreign_key     => 1,
    is_nullable        => 0,
};

=head1 RELATIONS

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
