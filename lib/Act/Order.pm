package Act::Order;
use Act::Object;
use base qw( Act::Object );

# class data used by Act::Object
our $table       = 'orders';
our $primary_key = 'order_id';

our %sql_stub    = (
    select => "o.*",
    from   => "orders o",
);
our %sql_mapping = (
    # standard stuff
    map( { ($_, "(o.$_=?)") }
         qw( order_id user_id conf_id amount paid ) )
);
our %sql_opts    = ( 'order by' => 'order_id' );

=head1 NAME

Act::Order - An Act object representing an order.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
