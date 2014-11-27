package Act::Schema::Result::PMGroup;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::PMGroup

Representaion of a Perl Mongers group

=head1 TABLE: C<pm_groups>

=cut

table "pm_groups";

=head1 ACCESSORS

=head2 group_id

Perl Mongers Group Primary Key

=cut

column "group_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    sequence           => 'pm_groups_group_id_seq',
};

=head2 xml_group_id

XML ID as being used in the Perl Mongers Group data-file

=cut

column "xml_group_id" => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 name

Name of the PM Group, usually the name of the city

=cut

column "name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 status

The current status of the group, unfortunatly, some Perl Monger groups become
inactive after some while.

=cut

column "status" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 continent

The conitnent where the group is located.

=cut

column "continent" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 country

The country where the group is located.

=cut

column "country" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 state

The state where the group is located.

=cut

column "state" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</group_id>

=back

=cut

primary_key "group_id";

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
