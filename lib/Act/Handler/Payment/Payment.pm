package Act::Handler::Payment::Payment;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    # for treasurers only
    if ($Request{user} && $Request{user}->is_treasurer) {
        if ($Request{args}{user_id}) {
            # fetch user
            my $user = Act::User->new(
                user_id => $Request{args}{user_id},
                conf_id => $Request{conference},
            );
            unless ($user->has_paid) {
                # payment means and prices
                my $means = Act::Payment::get_means();
                delete $means->{ONLINE};
                my $prices = Act::Payment::get_prices;

                if ($Request{args}{ok}) {
                    # payment form submission
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
                    # create an order row for this payment
                    Act::Order->create(
                        user_id  => $user->user_id,
                        conf_id  => $Request{conference},
                        amount   => $amount,
                        currency => $Config->payment_currency,
                        means    => $Request{args}{means},
                        price    => $price,
                        status   => 'paid',
                    );
                    # back to the payment list
                    return Act::Util::redirect(make_uri('payments'));
                }
                # display payment form
                my $template = Act::Template::HTML->new;
                $template->variables(
                    user   => $user,
                    means  => $means,
                    prices => $prices,
                    currency => $Config->payment_currency,
                );
                $template->process('payment/payment');
                return;
            }
        }
    }
    $Request{status} = NOT_FOUND;
}

1;
__END__

=head1 NAME

Act::Handler::Payment::Payment - enter a payment

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
