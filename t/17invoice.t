use Test::More tests => 5;
use strict;
use DateTime;
use t::Util;
use Act::Invoice;
use Act::Order;
use Act::User;

$Request{conference} = 'conf';

# create the invoice number sequence
{
    my $seq = join '_', 'invoice', $Request{conference}, 'seq';
    local $Request{dbh}{PrintError} = 0;
    $Request{dbh}->do("DROP SEQUENCE $seq")
        or $Request{dbh}->rollback;
    $Request{dbh}->do("CREATE SEQUENCE $seq");
    $Request{dbh}->commit;
}

# empty invoice
my $invoice = Act::Invoice->new();
isa_ok( $invoice, 'Act::Invoice' );
is_deeply( $invoice, {}, "create empty invoice with new()" );

# load some users
db_add_users();
my $user = Act::User->new( login => 'echo' );

# create an order
my %order_info = (
   amount    => 42,
   currency  => 'EUR',
   means     => 'ONLINE',
);
my %billing_info = (
   company     => 'Acme Inc',
   company_url => 'http://www.example.org',
   address     => '42 Recursive Drive, Palo Bajo',
);
my $order = Act::Order->create(
   user_id   => $user->user_id,
   conf_id   => $Request{conference},
   status    => 'paid',
   %order_info,
);

# create an invoice
my $now = DateTime->now();
$invoice = Act::Invoice->create(
    order_id => $order->order_id,
    %order_info,
    %billing_info,
);
isa_ok( $invoice, 'Act::Invoice', 'create()' );

# check the invoice value (it works because $order has only one invoice)
is_deeply( Act::Invoice->new( order_id => $order->order_id ),
  {
   invoice_id   => $invoice->invoice_id,
   order_id     => $order->order_id,
   datetime     => $now,
   invoice_no   => 1,
   %order_info,
   %billing_info,
  },
  "fetch"
);

# update
eval { $invoice->update() };
ok($@, "update");
