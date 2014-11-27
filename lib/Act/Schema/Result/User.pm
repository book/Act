package Act::Schema::Result::User;
use utf8;
use Act::Schema::Candy;

=head1 NAME

Act::Schema::Result::User

The User has aboiut all and every piece of data and many columns for personal
details.

Yes, this certainly could use an overhaul.

=head1 TABLE: C<users>

=cut

table "users";

=head1 ACCESSORS

=head2 user_id

Primary Key of this L<Act::Schema::Result::User> object.

=cut

column "user_id" => {
    data_type          => 'integer',
    is_auto_increment  => 1,
    sequence           => 'users_user_id_seq',
};

=head2 login

User Login ID

=cut

column "login" => {
    data_type          => 'text',
};

=head2 passwd

User login password

=cut

column "passwd" => {
    data_type          => 'text',
};

=head2 session_id

TODO: session_id keeps track of

=cut

column "session_id" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 salutation

Salutation like 'Mr.', 'Mrs.', 'Ms.' or 'Dr.'.

=cut

column "salutation" => {
    data_type          => 'integer',
    is_nullable        => 1,
};

=head2 first_name

User's First Name.

=cut

column "first_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 last_name

User's Last Name.

=cut

column "last_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 nick_name

User's Nick Name.

=cut

column "nick_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 pseudonymous

Flag to indicate wether or not to use 'Nick Name' or 'Real Name'.

=cut

column "pseudonymous" => {
    data_type          => 'boolean',
    default_value      => \"false",
    is_nullable        => 1,
};

=head2 country

User's country of residence.

=cut

column "country" => {
    data_type          => 'text',
};

=head2 town

User's town of residenc.

=cut

column "town" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 web_page

URL of the personal web page.

=cut

column "web_page" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 pm_group

Comma seperated list of Perl Monger groups.

=cut
column "pm_group" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 pm_group_url

URL of main Perl Mongers group.

=cut

column "pm_group_url" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 email

User's e-mail address for Act communication.

=cut

column "email" => {
    data_type          => 'text',
};

=head2 email_hide

Flag to indicate if this email address can be shared with the public or not.

=cut

column "email_hide" => {
    data_type          => 'boolean',
    default_value      => \"true",
};

=head2 gpg_key_id

GPG public key ID.

=cut

column "gpg_key_id" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 pause_id

User's PAUSE ID on CPAN.

=cut

column "pause_id" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 monk_id

The Perl Monk ID for this user. See L<Perl Monks|http://www.perlmonks.org>.

=cut

column "monk_id" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 monk_name

The Perl Monk name as the user goes by. (manually entered).

=cut

column "monk_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 im

Any Instant Messaging ID's

=cut

column "im" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 photo_name

The name of the file being used to display a profile picture.

=cut

column "photo_name" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 language

TODO:

=cut

column "language" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 timezone

The user's Timezone of residence.

=cut

column "timezone" => {
    data_type          => 'text',
};

=head2 company

The company the user works for.

=cut

column "company" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 company_url

The URL for the company.

=cut

column "company_url" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 address

User's full address, multi line value.

=cut

column "address" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head2 vat

VAT Number for those that have buisiness tax rules.

=cut

column "vat" => {
    data_type          => 'text',
    is_nullable        => 1,
};

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

primary_key "user_id";

=head1 UNIQUE CONSTRAINTS

=head2 C<users_login>

=over 4

=item * L</login>

=back

=cut

unique_constraint "users_login" => ["login"];

=head2 C<users_session_id>

=over 4

=item * L</session_id>

=back

=cut

unique_constraint "users_session_id" => ["session_id"];

=head1 RELATIONS

=head2 orders

has_many related object: L<Act::Schema::Result::Order>

=cut

has_many "orders" => "Act::Schema::Result::Order",
    { "foreign.user_id" => "self.user_id" },
    {},
;

=head2 participations

has_many related object: L<Act::Schema::Result::Participation>

=cut

has_many "participations" => "Act::Schema::Result::Participation",
    { "foreign.user_id" => "self.user_id" },
    {},
;

=head2 rights

has_many related object: L<Act::Schema::Result::Right>

=cut

has_many "rights" => "Act::Schema::Result::Right",
    { "foreign.user_id" => "self.user_id" },
    {},
;

=head2 talks

has_many related object: L<Act::Schema::Result::Talk>

=cut

has_many "talks" => "Act::Schema::Result::Talk",
    { "foreign.user_id" => "self.user_id" },
    {},
;

=head2 user_talks

has_many related object: L<Act::Schema::Result::UserTalk>

=cut

has_many "user_talks" => "Act::Schema::Result::UserTalk",
    { "foreign.user_id" => "self.user_id" },
    {},
;

=head1 COPYRIGHT

(c) 2014 - Th.J. van Hoesel - THEMA-MEDIA NL

=cut

1;
