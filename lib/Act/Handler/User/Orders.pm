package Act::Handler::User::Orders;

use strict;
use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Template::HTML;
use Act::Order;

sub handler
{
    # registered users only
    unless ($Request{user}->has_registered() && $Config->payment_type ne 'NONE') {
        $Request{status} = NOT_FOUND;
        return;
    }
    # get his orders
    my $orders = Act::Order->get_items(
                    user_id => $Request{user}->user_id(),
                    conf_id => $Request{conference},
                    status  => 'paid',
                 );

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        orders => $orders,
    );
    $template->process('user/orders');
}

1;
__END__

=head1 NAME

Act::Handler::User::Orders - user's purchase orders summary

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
