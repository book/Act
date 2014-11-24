package Act::Schema::Result::Track;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Track

=head1 DESCRIPTION

TODO:

=head1 TABLE: C<tracks>

=cut

table "tracks";

=head1 ACCESSORS

=head2 track_id

Primary Key

=cut

column "track_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    is_nullable        => 0,
    sequence           => 'tracks_track_id_seq',
};

=head2 conf_id

Cummunity Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 title

Track Title

=cut

column "title" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 description

Description of this track

=cut

column "description" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</track_id>

=back

=cut

primary_key "track_id";

=head1 RELATIONS

=head2 talks

has_many related object: L<Act::Schema::Result::Talk>

=cut

has_many "talks" => "Act::Schema::Result::Talk",
  { "foreign.track_id" => "self.track_id" },
  { cascade_copy => 0, cascade_delete => 0 };

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
