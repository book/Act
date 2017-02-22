package Act::Schema::Result::Talk;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Talk

=head1 DESCRIPTION

Contains all info for a specific talk. Talks are Cummunity Event related and
althoug common practice to repeat a talk at several occasions, it needs a
seperate entry.

=head1 TABLE: C<talks>

=cut

table "talks";

=head1 ACCESSORS

=head2 talk_id

Primary Key

=cut

column "talk_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    sequence           => 'talks_talk_id_seq',
};

=head2 conf_id

Community Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
};

=head2 user_id

Foreign Key for L<Act::Schema::Result::User>.

=cut

column "user_id" => {
    data_type          => 'integer',
};

=head2 title

The title of this talk

=cut

column "title" => {
    data_type          => 'text',
};

=head2 abstract

Description of the talk

=cut

column "abstract" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 url_abstract

External link to the abstract

=cut

column "url_abstract" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 url_talk

External link to more info of this talk

=cut

column "url_talk" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 duration

Duration in . . . .

=cut

column "duration" => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 lightning

Flag to indicate if this is a lightning talk. Lightning talks do not get their
own entry in the schedule.

=cut

column "lightning" => {
    data_type          => 'boolean',
    default_value      => \"false",
};

=head2 accepted

Flag to indicate if this talk has been accepted by the 'talks admin'.

=cut

column "accepted" => {
    data_type          => 'boolean',
    default_value      => \"false",
};

=head2 confirmed

Flag to indicate if the talk has been confirmed by the presentor after
acceptance

=cut

column "confirmed" => {
    data_type          => 'boolean',
    default_value      => \"false",
};

=head2 comment

Any comments that the 'talks admin' should know about, not available for the public.

=cut

column "comment" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 room

The room the presentation will be held. Can be changed by the 'talks admin'.

=cut

column "room" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 datetime

Date and Time of the presentation. Can be changed by the 'talks admin'.

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 1,
};

=head2 track_id

Foreign Key for L<Act::Schema::Result::Track>. Presentations can be part of a 'track' as a serie.

=cut

column "track_id" => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 level

The level this presentation is addressed, usually on off: (1) Any, (2)
Beginner, (3) Intermediate or (4) Advanced.

=cut

column "level" => {
    data_type          => 'integer',
    default_value      => 1,
    is_nullable        => 1,
};

=head2 lang

The language this presentayion wil be held in

=cut

column "lang" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</talk_id>

=back

=cut

primary_key "talk_id";

=head1 RELATIONS

=head2 track

belongs_to related object: L<Act::Schema::Result::Track>

=cut

belongs_to "track" => "Act::Schema::Result::Track",
    { track_id => "track_id" },
    {
      join_type     => "LEFT",
      on_delete     => "SET NULL",
    }
;

=head2 user

belongs_to related object: L<Act::Schema::Result::User>

=cut

belongs_to "user" => "Act::Schema::Result::User",
    { user_id => "user_id" },
    {},
;

=head2 user_talks

has_many related object: L<Act::Schema::Result::UserTalk>

=cut

has_many "user_talks" => "Act::Schema::Result::UserTalk",
    { "foreign.talk_id" => "self.talk_id" },
    {},
;

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
