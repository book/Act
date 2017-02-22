package Act::Schema::Result::UserTalk;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::UserTalk

=head1 TABLE: C<user_talks>

=cut

table "user_talks";

=head1 ACCESSORS

=head2 user_id

Foreign Key for L<Act::Schema::Result::User>.

=cut

column "user_id" => {
    data_type          => 'integer',
};

=head2 conf_id

Community Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
};

=head2 talk_id

Foreign Key for L<Act::Schema::Result::Talk>.

=cut

column "talk_id" => {
    data_type          => 'integer',
};


=head1 RELATIONS

=head2 talk

belongs_to related object: L<Act::Schema::Result::Talk>

=cut

belongs_to "talk" => "Act::Schema::Result::Talk",
    { talk_id => "talk_id" },
    {},
;

=head2 user

belongs_to related object: L<Act::Schema::Result::User>

=cut

belongs_to "user" => "Act::Schema::Result::User",
    { user_id => "user_id" },
    {},
;

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
