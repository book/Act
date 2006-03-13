package Act::PMGroup;
use Act::Object;
use base qw( Act::Object );

# class data used by Act::Object
our $table       = 'pm_groups';
our $primary_key = 'group_id';

our %sql_stub    = (
    select => "g.*",
    from   => "pm_groups g",
);
our %sql_mapping = (
    name         => "(g.name~*?)",
    # standard stuff
    map( { ($_, "(g.$_=?)") } qw( group_id xml_group_id ) )
);
our %sql_opts    = ( 'order by' => 'name' );

*get_pm_group = \&Act::Object::get_items;

=head1 NAME

Act::PMGroup - An Act object representing a Perl Monger group.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;

