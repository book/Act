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
    my $order_id = $Request{path_info} || $Request{args}{order_id};
    unless ($order_id =~ /^\d+$/) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # get the order
    my $order   = Act::Order->new(   order_id => $order_id );

    # only a treasurer or the client can see the invoice
    unless ( $order
        &&  ($Request{user}->user_id == $order->user_id || $Request{user}->is_treasurer))
    {
        $Request{status} = FORBIDDEN;
        return;
    }

    # get the invoice
    my $template = Act::Template::HTML->new();
    my $invoice = Act::Invoice->new( order_id => $order_id );

    # invoice doesn't exist
    unless ($invoice) {
        # user confirms billing info
        if ($Request{args}{ok}) {
            # create invoice
            $invoice = Act::Invoice->create(
                (map { $_ => $order->$_ }         qw(order_id amount currency means)),
                (map { $_ => $Request{user}->$_ } qw( first_name last_name company address )),
            );
        }
        else {
            # display billing info confirmation form
            $template->variables(order_id => $order_id);
            $template->process('payment/confirm_invoice');
            return;
        }
    }

    # process the template
    $template->variables( %{$invoice}, today => DateTime->now );
    $template->process('payment/invoice');
}

1;

