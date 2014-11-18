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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-11-18 10:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jcSCIMqGws58QR2Su8GeCg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
