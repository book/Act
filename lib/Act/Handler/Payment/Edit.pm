package Act::Handler::Payment::Edit;
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
    # for treasurers only
    return unless $Request{user}->is_treasurer
               && ($Request{args}{user_id} ); # || $Request{args}{order_id});

    # payment means and prices
    my $means  = Act::Payment::get_means;
    my ($productlist, $products) = Act::Payment::get_prices;

    # fetch user (create payment) or order (edit payment)
    my ($user, $order);
    if ($Request{args}{user_id}) {
        $user = Act::User->new(
            user_id => $Request{args}{user_id},
            conf_id => $Request{conference},
        );
        return unless $user;
    }
    else {
        return;
        $order = Act::Order->new( order_id  => $Request{args}{order_id} );
        return unless $order
                && exists $means->{$order->means}  # edit existing except online
                && !Act::Invoice->new( order_id => $order->order_id );
        $user = Act::User->new($order->user_id);
    }
    if ($Request{args}{ok}) {
        # payment form submission
        my @items;
        for my $p (@$productlist) {
            if ($Request{args}{"product-$p"}) {
                my $product = $products->{$p};
                my $nprices = @{$product->{prices}};
                my $price_id;
                if ($nprices == 1) {
                    $price_id = 1;
                }
                else {
                    $price_id = $Request{args}{"price-$p"};
                }
                my $price = $product->{prices}[$price_id-1];
                my $name = $product->{name};
                $name = join(' - ', $name, $price->{name}) if $price->{name};
                push @items, {
                    amount => $Request{args}{means} eq 'FREE' ? 0 : $price->{amount},
                    name   => $name,
                    registration => $p eq 'registration',
                };
            }
        }
        # create or update the order
        if ($order) {
            # FIXME
            # $order->update(...);
        }
        else {
            Act::Order->create(
                user_id  => $user->user_id,
                conf_id  => $Request{conference},
                means    => $Request{args}{means},
                type     => $Config->payment_type,
                currency => $Config->payment_currency,
                status   => 'paid',
                items    => \@items,
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
        has_paid  => $user->has_paid,
        allmeans  => $means,
        currency  => $Config->payment_currency,
        productlist => $productlist,
        products    => $products,
    );
    $template->process('payment/edit');
    return 1;
}

1;
__END__

=head1 NAME

Act::Handler::Payment::Edit - enter/edit a payment (treasurer)

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
