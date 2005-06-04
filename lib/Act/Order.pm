package Act::Order;
use strict;
use DateTime;
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
         qw( order_id user_id conf_id amount means currency status ) )
);
our %sql_opts    = ( 'order by' => 'order_id' );

sub create {
    my ($class, %args ) = @_;
    $args{datetime} = DateTime->now();
    return $class->SUPER::create(%args);
}
sub update {
    my ($self, %args ) = @_;
    $args{datetime} = DateTime->now();
    return $self->SUPER::update(%args);
}
=head1 NAME

Act::Order - An Act object representing an order.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
