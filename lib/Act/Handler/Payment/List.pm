package Act::Handler::Payment::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use DateTime;

use Act::Config;
use Act::Invoice;
use Act::Order;
use Act::Payment;
use Act::Template::HTML;
use Act::User;
use Act::Util;

*_n = \&Act::Util::normalize;

my %sortsub = (
    user    => sub { [ Act::Util::usort { $_->last_name } @{$_[0]} ] },
    status  => sub { my $users = shift;
                return [ sort {
                    # sort users with rights first
                    my ($sa, $sb) = map $_->{status}, $a, $b;
                      @$sa && @$sb ? join('', @$sa) cmp join('', @$sb)
                                                    ||
                                     _n($a->last_name) cmp _n($b->last_name)
                    : @$sa         ? -1
                    : @$sb         ? 1
                    :                _n($a->last_name) cmp _n($b->last_name)
                } @$users ]
        

               },
);
# hack to let TT access 'status'
sub Act::User::status { $_[0]->{status} }

sub handler
{
    # for treasurers only
    unless ($Request{user} && $Request{user}->is_treasurer)
    {
        $Request{status} = NOT_FOUND;
        return;
    }
    # retrieve users and their payment info
    my $users = Act::User->get_items( conf_id => $Request{conference} );
    my $means  = Act::Payment::get_means;
    my (%orders, %total);
    for my $u (@$users) {
        $u->{status} = [ keys %{ $u->rights },
            $u->has_accepted_talk ? 'speaker' : () ];

        my $orders = Act::Order->get_items(
            user_id  => $u->user_id,
            conf_id  => $Request{conference},
            status   => 'paid',
        );
        for my $order (@$orders) {
            my $invoice = Act::Invoice->new( order_id => $order->order_id );
            if ($invoice) {
                $order->{invoice_no} = $invoice->invoice_no;
            }
            else {
                # editable if created by treasurer, no invoice, same currency
                $order->{editable} = exists $means->{$order->means}
                                    && $order->currency eq $Config->payment_currency;
            }
            $order->{means} = localize('payment_means_' . $order->means);
            $order->{invoice_uri} = make_uri_info('invoice', $order->order_id);
            $total{ $order->currency } += $order->amount;
        }
        $orders{$u->user_id} = $orders if @$orders;
    }
    # sort key
    my $sortkey = $Request{args}{sort};
    $sortkey = 'user' unless $sortkey && exists $sortsub{$sortkey};

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        users       => $sortsub{$sortkey}->($users),
        orders      => \%orders,
        sortkey     => $sortkey,
        total       => \%total,
    ); 
    $template->process('payment/list');
}

1;
__END__

=head1 NAME

Act::Handler::Payment::List - show all payments

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
