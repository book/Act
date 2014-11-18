use utf8;
package Act::Schema::Result::Track;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Track

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tracks>

=cut

__PACKAGE__->table("tracks");

=head1 ACCESSORS

=head2 track_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tracks_track_id_seq'

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "track_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tracks_track_id_seq",
  },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</track_id>

=back

=cut

__PACKAGE__->set_primary_key("track_id");

=head1 RELATIONS

=head2 talks

Type: has_many

Related object: L<Act::Schema::Result::Talk>

=cut

__PACKAGE__->has_many(
  "talks",
  "Act::Schema::Result::Talk",
  { "foreign.track_id" => "self.track_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rPHCtjKqOhSGU6ma65tffg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
