use Test::More tests => 6;
use strict;
use t::Util;
use Act::Order;
use Act::User;

use constant AMOUNT => 42;

# empty order
my $order = Act::Order->new();
isa_ok( $order, 'Act::Order' );
is_deeply( $order, {}, "create empty order with new()" );

# load some users
db_add_users();
my $user = Act::User->new( login => 'echo' );

# create an order
my $order = Act::Order->create(
   user_id   => $user->user_id,
   conf_id   => 'conf',
   amount    => AMOUNT,
);
isa_ok( $order, 'Act::Order', 'create()' );

# check the order value (it works because $user has only one order)
is_deeply( Act::Order->new( user_id => $user->user_id ),
   {
   order_id     => $order->order_id,
   user_id      => $user->user_id,
   conf_id      => 'conf',
   amount       => AMOUNT,
   paid         => 0,
   },
  "fetch" );

# update
$order->update(paid => 1);
is_deeply(  Act::Order->new( order_id => $order->order_id ),
   {
   order_id     => $order->order_id,
   user_id      => $user->user_id,
   conf_id      => 'conf',
   amount       => AMOUNT,
   paid         => 1,
   },
  "update" );

# reload the user, since the order was added after we got him
$user = Act::User->new( user_id => $user->user_id, conf_id => 'conf' );
ok( $user->has_paid, "User has paid" );
