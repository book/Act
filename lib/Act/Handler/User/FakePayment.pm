package Act::Handler::User::FakePayment;

use Act::Config;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;
use Act::Util;

sub handler
{
    # shouldn't get here unless the online payment is open
    # and this user hasn't paid
    unless ($Config->payment_open && !$Request{user}->has_paid) {
        $Request{status} = NOT_FOUND;
        return;
    }

    $Request{r}->no_cache(1);
    my $template = Act::Template::HTML->new();

    # verify payment
    my $order = Act::Payment->verify($Request{args});
    if ($order) {

        # update order
        $order->update(paid => 1);
    }
    # back to the user's main page
    Act::Util::redirect(make_uri('main'));
}

1;
__END__

=head1 NAME

Act::Handler::User::Payment - confirm payment

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
