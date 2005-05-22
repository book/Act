package Act::Handler::Payment::Invoice;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Template::HTML;
use Act::Config;
use Act::User;
use Act::Invoice;
use Act::Order;

sub handler
{
    # retrieve order_id
    my $order_id = $Request{path_info};
    unless ($order_id =~ /^\d+$/) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # get the order and invoice
    # shall we limit those to the current conference?
    my $order   = Act::Order->new(   order_id => $order_id );
    my $invoice = Act::Invoice->new( order_id => $order_id );

    # both must exist
    if( ! defined $invoice || ! defined $order ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # FIXME the address must exist for us to create the invoice

    # only a treasurer or the client can see the invoice
    if ( ! ( $Request{user}->user_id == $order->user_id && $order->invoice_ok )
        || $Request{user}->is_treasurer )
    {
        $Request{status} = FORBIDDEN;
        return;
    }

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( %{$invoice} );
    $template->process('payment/invoice');
}

1;

