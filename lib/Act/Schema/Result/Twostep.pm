use utf8;
package Act::Schema::Result::Twostep;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Twostep

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<twostep>

=cut

__PACKAGE__->table("twostep");

=head1 ACCESSORS

=head2 token

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 datetime

  data_type: 'timestamp'
  is_nullable: 1

=head2 data

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "token",
  { data_type => "char", is_nullable => 0, size => 32 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "datetime",
  { data_type => "timestamp", is_nullable => 1 },
  "data",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</token>

=back

=cut

__PACKAGE__->set_primary_key("token");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vXv2ERD+7+V6D99PBZQh4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
