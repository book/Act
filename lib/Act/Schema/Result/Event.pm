use utf8;
package Act::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Event

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<events>

=cut

__PACKAGE__->table("events");

=head1 ACCESSORS

=head2 event_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'events_event_id_seq'

=head2 conf_id

  data_type: 'text'
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 url_abstract

  data_type: 'text'
  is_nullable: 1

=head2 room

  data_type: 'text'
  is_nullable: 1

=head2 duration

  data_type: 'integer'
  is_nullable: 1

=head2 datetime

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "event_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "events_event_id_seq",
  },
  "conf_id",
  { data_type => "text", is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "url_abstract",
  { data_type => "text", is_nullable => 1 },
  "room",
  { data_type => "text", is_nullable => 1 },
  "duration",
  { data_type => "integer", is_nullable => 1 },
  "datetime",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</event_id>

=back

=cut

__PACKAGE__->set_primary_key("event_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NLOTDXVl8O2TnEBCFWd1sA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
