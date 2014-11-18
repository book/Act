package Act::Schema::Candy;

use base 'DBIx::Class::Candy';

sub base { $_[1] || 'Act::Schema::Result' }
# sub perl_version { 12 }
sub autotable { 1 }
