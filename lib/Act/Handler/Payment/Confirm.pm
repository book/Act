package Act::Handler::Payment::Confirm;
use strict;

use Act::Config;
use Act::Payment;

sub handler
{
    # we aren't dispatched by Act::Dispatcher
    $Request{args} = { map { $_ => $Request{r}->param($_) || '' } $Request{r}->param };

    # verify payment
    my ($verified, $order) = Act::Payment->verify($Request{args});
    if ($verified && $order) {
        # update order
        $order->update(status => 'paid',
                       means  => 'ONLINE'
                      );
    }
    Act::Payment->create_response($verified, $order);
}

1;
__END__

=head1 NAME

Act::Handler::Payment::Confirm - confirm a payment.

=head1 DESCRIPTION

This handler is called by the bank with the status
of a paement.

See F<DEVDOC> for a complete discussion on handlers.

=cut
