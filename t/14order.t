use Test::More tests => 16;
use strict;
use t::Util;
use Act::Order;
use Act::User;

$Request{conference} = 'conf'; # required for has_* methods

# empty order
my $order = Act::Order->new();
isa_ok( $order, 'Act::Order' );
is_deeply( $order, {}, "create empty order with new()" );

# load some users
db_add_users();
my $user = Act::User->new( login => 'echo' );

_test(
  {
    amount          => 75,
    name            => 'A Room with a View',
    registration    => 0,
  },
  {
    amount          => 25,
    name            => 'La grande bouffe',
    registration    => 0,
  },
);
ok( !$user->has_paid, "User has paid" );

# test order with registration product
_test(
  {
    amount          => 50,
    name            => 'Registration',
    registration    => 1,
  },
);
ok( $user->has_paid, "User has paid" );

sub _test
{
    my @items = @_;

    # create a new order
    my $order = Act::Order->create(
       user_id   => $user->user_id,
       conf_id   => 'conf',
       currency  => 'EUR',
       status    => 'init',
       type      => 'FOO',
       items     => \@items,
    );
    isa_ok( $order, 'Act::Order', 'create()' );

    # fetch
    my $fetched = Act::Order->new( order_id => $order->order_id );
    is_deeply($fetched, $order, "fetch");
    my $fetched_items = $fetched->items;
    delete $_->{item_id} for @$fetched_items;
    is_deeply($fetched_items, \@items, "items");

    # reload the user, since the order was added after we got him
    $user = Act::User->new( user_id => $user->user_id, conf_id => 'conf' );
    ok( !$user->has_paid, "User hasn't paid" );

    # update
    $order->update(status => 'paid', means => 'ONLINE');
    $fetched = Act::Order->new( order_id => $order->order_id );
    is_deeply($fetched, $order, "update");
    $fetched_items = $fetched->items;
    delete $_->{item_id} for @$fetched_items;
    is_deeply($fetched_items, \@items, "items");

    # reload the user, since the order was updated after we got him
    $user = Act::User->new( user_id => $user->user_id, conf_id => 'conf' );
}

