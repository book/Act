use utf8;
package Act::Schema::Result::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Act::Schema::Result::Schema

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<schema>

=cut

__PACKAGE__->table("schema");

=head1 ACCESSORS

=head2 current_version

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "current_version",
  { data_type => "integer", is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-07-31 16:42:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r3lp7XEwL5zsZhK6jz1uuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
