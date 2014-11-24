package Act::Schema::Result::Event;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Event

=head DESCRIPTION

Scheduled Events are the moments in a schedule that are not a user talk. These
are ussually used to indicate coffee breaks, registration and others. See the
manuals on about "Schedule" how it exactly works.

=head1 TABLE: C<events>

=cut

table "events";

=head1 ACCESSORS

=head2 event_id

=cut

column "event_id" => {
    data_type         => 'integer',
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => 'events_event_id_seq',
};

=head2 conf_id

Community Event ID

=cut

column "conf_id" => {
    data_type            => 'text',
    is_nullable          => 0,
};

=head2 title

Title of the Scheduled Event.

=cut

column "title" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 abstract

Short descriotion of the Scheduled Event

=cut

column "abstract" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 url_abstract

URL leading to more information about this particular Scheduled Event.

=cut

column "url_abstract" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 room

The identifier of the room, wich is either "out", "sidetrack" or "venue".

=cut

column "room" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 duration

Duration of the Scheduled Event in ...

=cut

column "duration" => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 datetime

Start date and time of the Scheduled Event.

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</event_id>

=back

=cut

primary_key "event_id";

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
