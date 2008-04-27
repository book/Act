package Act::Handler::User::Purchase;
use strict;
use Apache::Constants qw(NOT_FOUND);
use List::Util qw(first);

use Act::Config;
use Act::Form;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;
use Act::Util;

my $form = Act::Form->new(
    optional => [qw(donation)],
    constraints => {
        donation => 'numeric',
    }
);
sub handler
{
    # shouldn't get here unless online payment is open,
    # and this user is registered 
    unless ($Config->payment_type ne 'NONE' &&
            $Config->payment_open &&
            $Request{user}->has_registered())
    {
        $Request{status} = NOT_FOUND;
        return;
    }

    $Request{r}->no_cache(1);
    my $template = Act::Template::HTML->new();
    my ($productlist, $products) = Act::Payment::get_prices;
    my $fields;

    if ($Request{args}{purchase}) {
        # form has been submitted
        # validate form fields
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};
        # validate products and prices
        my @items;
        for my $p (@$productlist) {
            if ($Request{args}{"product-$p"}) {
                my $product = $products->{$p};
                $product->{checked} = 1;
                my $nprices = @{$product->{prices}};
                my $price_id;
                if ($nprices == 1) {
                    $price_id = 1;
                }
                else {
                    my $promocode = $Request{args}{"promo-$p"};
                    if ($promocode) {   # promotion code supplied
                        $fields->{promo}{$p} = $promocode;
                        my $id = first { $product->{prices}[$_-1]{promocode} eq $promocode } 1..$nprices;
                        if ($id) {
                            $price_id = $id;
                        }
                        else {
                            $ok = 0;
                        }
                    }
                    else {
                        my $id = $Request{args}{"price-$p"};
                        if ($id >= 1 && $id <= $nprices) {
                            $price_id = $id;
                        }
                        else {
                            $ok = 0;
                        }
                    }
                }
                if ($price_id) {
                    my $price = $product->{prices}[$price_id-1];
                    my $name = $product->{name};
                    $name = join(' - ', $name, $price->{name}) if $price->{name};
                    push @items, {
                        amount => $price->{amount},
                        name   => $name,
                        registration => $p eq 'registration',
                    };
                    $price->{checked} = 1;
                }
            }
            elsif ($Request{args}{"promo-$p"} || $Request{args}{"price-$p"}) {
                # user selected a price or entered a promo code,
                # but didn't check the product checkbox
                $fields->{promo}{$p} = $Request{args}{"promo-$p"};
                $products->{$p}{prices}[$Request{args}{"price-$p"}-1]{checked}
                    = $Request{args}{"price-$p"};
                $ok = 0;
            }
        }
        if ($ok && $fields->{donation}) {
            push @items, {
                amount => $fields->{donation},
                name   => localize('Donation'),
            };
        }
        $ok = @items > 0 if $ok;
        if ($ok) {
            # always a use a newly created order
            # (some banks will only process a given order_id once)
            my %f = (
                user_id  => $Request{user}{user_id},
                conf_id  => $Request{conference},
                currency => $Config->payment_currency,
                type     => $Config->payment_type,
                means    => 'ONLINE',
                status   => 'init',
                items    => \@items,
            );
            my $order = Act::Order->create(%f);
    
            my $total_amount;
            $total_amount+=$_->{amount} for @items;

            if ($total_amount > 0) {
                # display second form (submits to the bank)
                my $plugin = Act::Payment::load_plugin();
                $template->variables_raw(form => $plugin->create_form($order));
                $template->variables(order => $order);
                $template->process('user/payment');
                return;
            }
            else {
                # nothing to pay
                $order->update(status=>'paid');
                # XXX should we send a confirmation e-mail?
                $template->variables(order => $order);
                $template->process('user/zeropayment');
                return;
            }
        }
    }
    # display the first form
    $template->variables(
        currency    => $Config->payment_currency,
        productlist => $productlist,
        products    => $products,
        %$fields,
    );
    $template->process('user/purchase');
}

1;
__END__

=head1 NAME

Act::Handler::User::Purchase - purchase conference ticket

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
