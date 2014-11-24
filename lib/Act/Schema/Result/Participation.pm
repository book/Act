package Act::Schema::Result::Participation;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::Participation

=head1 DESCRIPTION

Holds data per user participation

=head1 TABLE: C<participations>

=cut

table "participations";

=head1 ACCESSORS

=head2 conf_id

Cummunity Event ID

=cut

column "conf_id" => {
    data_type          => 'text',
    is_nullable        => 0,
};

=head2 user_id

Foreign Key to L<Act::Schema::Result::User>

=cut

column "user_id" => {
    data_type          => 'integer',
    is_foreign_key     => 1,
    is_nullable        => 0,
};

=head2 tshirt_size

Size of the t-shirt, which seems to vary over time

=cut

column "tshirt_size" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 nb_family

Number of family members comming with this participation

=cut

column "nb_family" => {
    data_type          => 'integer',
    default_value      => 0,
    is_nullable        => 1,
};

=head2 datetime

Timestamp

=cut

column "datetime" => {
    data_type          => 'timestamp',
    is_nullable        => 1,
};

=head2 ip

IP-Address at the time of . . . .

=cut

column "ip" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 attended

Flag to indicate if the participant actual showed up

=cut

column "attended" => {
    data_type          => 'boolean',
    default_value      => \"false",
    is_nullable        => 1,
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

1;
