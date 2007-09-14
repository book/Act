package Act::Handler::Payment::Payment;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Invoice;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    _handler() or $Request{status} = NOT_FOUND;
}
sub _handler
{
    # for non-free conferences, treasurers only
    return unless $Config->payment_type ne 'NONE'
               && $Request{user}->is_treasurer
               && $Request{args}{user_id};

    # payment means and prices
    my $means  = Act::Payment::get_means;
    my $prices = Act::Payment::get_prices;

    # fetch user
    my $user = Act::User->new(
        user_id => $Request{args}{user_id},
        conf_id => $Request{conference},
    );
    return unless $user;

    # fetch order
    my $order = Act::Order->new(
            user_id  => $Request{args}{user_id},
            conf_id  => $Request{conference},
            status   => 'paid',
    );
    # can create payment,
    if ($order) {
        # edit existing except online
        return unless exists $means->{$order->means};
        # or if invoice already generated
        my $invoice = Act::Invoice->new( order_id => $order->order_id );
        return if $invoice;
    }
    if ($Request{args}{ok}) {
        # payment form submission
        return if $Request{args}{order_id} && $Request{args}{order_id} != $order->order_id;
        my %prices = map { $_->{price_id} => $_ } @$prices;
        my ($amount, $price);
        if ($Request{args}{means} eq 'FREE') {
            $amount = 0;
        }
        elsif ($Request{args}{amount}) {
            $amount = $Request{args}{amount};
        }
        else {
            $amount = $prices{$Request{args}{price}}{amount};
            $price  = $prices{$Request{args}{price}}{name};
        }
        # create or update the order
        if ($order) {
            $order->update(
                means    => $Request{args}{means},
                price    => $price,
                amount   => $amount,
            )
        }
        else {
            Act::Order->create(
                user_id  => $user->user_id,
                conf_id  => $Request{conference},
                means    => $Request{args}{means},
                price    => $price,
                amount   => $amount,
                currency => $Config->payment_currency,
                status   => 'paid',
            );
        }
        # back to the payment list
        Act::Util::redirect(make_uri('payments'));
        return 1;
    }
    # display payment form
    my $template = Act::Template::HTML->new;
    $template->variables( %$order ) if $order;
    $template->variables(
        user      => $user,
        allmeans  => $means,
        prices    => $prices,
        currency  => $Config->payment_currency,
    );
    $template->process('payment/payment');
    return 1;
}

1;
__END__

=head1 NAME

Act::Handler::Payment::Payment - enter a payment

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
