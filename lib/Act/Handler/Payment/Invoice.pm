package Act::Handler::Payment::Invoice;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Template::HTML;
use Act::Config;
use Act::User;
use Act::Invoice;

sub handler {

    # get the order and invoice
    my $order   = Act::Order->new(   order_id => $Request{path_info} );
    my $invoice = Act::Invoice->new( order_id => $Request{path_info} );

    # both must exist
    if( ! defined $invoice || ! defined $order ) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # only a treasurer or the client can see the invoice
    if ( ( $Request{user}->user_id == $order->user_id && $order->invoice_ok )
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

