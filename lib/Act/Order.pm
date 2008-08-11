package Act::Order;
use strict;
use DateTime;
use List::Util qw(first sum);

use Act::Config;
use Act::Object;
use Act::Util;
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
         qw( order_id user_id conf_id means currency status type ) )
);
our %sql_opts    = ( 'order by' => 'order_id' );

sub create {
    my ($class, %args ) = @_;
    $args{datetime} = DateTime->now();
    my $items = delete $args{items};
    my $order = $class->SUPER::create(%args);
    if ($order && $items) {
        for my $item (@$items) {
            sql('INSERT INTO order_items ( order_id, amount, name, registration ) VALUES (?, ?, ?, ?)',
                $order->order_id, $item->{amount}, $item->{name}, $item->{registration} ? 't' : 'f' );
        }
        $Request{dbh}->commit;
    }
    return $order;
}
sub update {
    my ($self, %args ) = @_;
    $args{datetime} = DateTime->now();
    return $self->SUPER::update(%args);
}
sub items
{
    my $self = shift;
    return $self->{items} if exists $self->{items};

    # fill the cache if necessary
    my $sth = sql("SELECT item_id, amount, name, registration FROM order_items WHERE order_id = ?",
                  $self->order_id);

    $self->{items} = [];
    while( my ($item_id, $amount, $name, $registration) = $sth->fetchrow_array() ) {
        push @{ $self->{items} }, { item_id      => $item_id,
                                    amount       => $amount,
                                    name         => $name,
                                    registration => $registration,
                                   };
    }
    $sth->finish();
    return $self->{items};
}

# return true if this order contains a registration item
sub registration { first { $_->{registration} } @{ $_[0]->items } }

# total amount
sub amount { sum map $_->{amount}, @{ $_[0]->items } }

# order title - used by payment plugins
sub title { localize('Your <conf> order #<id>', $Config->name->{$Request{language}}, $_[0]->order_id) }

=head1 NAME

Act::Order - An Act object representing an order.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
