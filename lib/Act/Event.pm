package Act::Event;
use Act::Object;
use base qw( Act::Object );

# class data used by Act::Object
our $table       = 'events';
our $primary_key = 'event_id';

our %sql_stub    = (
    select => "t.*",
    from   => "events t",
);
our %sql_mapping = (
    map( { ($_, "(t.$_=?)") }
         qw( event_id conf_id duration room datetime ) )
);
our %sql_opts    = ( 'order by' => 'datetime' );

*get_events = \&Act::Object::get_items;

=head1 NAME

Act::Event - An Act object representing a event.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;

