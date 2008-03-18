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
    status  => sub { my ($users, $orders) = @_;
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
    date    => sub { my ($users, $orders) = @_;
                return [ sort {
                    # sort users with payments first
                    my ($oa, $ob) = map $orders->{$_->user_id}, $a, $b;
                      $oa && $ob ? DateTime->compare($oa->datetime, $ob->datetime)
                    : $oa        ? -1
                    : $ob        ? 1
                    :              _n($a->last_name) cmp _n($b->last_name)
                } @$users ]
               },
    means   => sub { my ($users, $orders) = @_;
                return [ sort {
                    # sort users with payments first
                    my ($oa, $ob) = map $orders->{$_->user_id}, $a, $b;
                      $oa && $ob ? $oa->means cmp $ob->means
                    : $oa        ? -1
                    : $ob        ? 1
                    :              _n($a->last_name) cmp _n($b->last_name)
                } @$users ]
             },
    price   => sub {
                my ($users, $orders) = @_;
                return [ sort {
                    # sort users with payments first
                    my ($oa, $ob) = map $orders->{$_->user_id}, $a, $b;
                      $oa && $ob ? $oa->amount <=> $ob->amount
                                               ||
                                   _n($a->last_name) cmp _n($b->last_name)
                    : $oa        ? -1
                    : $ob        ? 1
                    :              _n($a->last_name) cmp _n($b->last_name)
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
    my (%orders, %invoice_uri, %total);
    for my $u (@$users) {
        $u->{status} = [ keys %{ $u->rights },
            $u->has_accepted_talk ? 'speaker' : () ];

        my $order = Act::Order->new(
            user_id  => $u->user_id,
            conf_id  => $Request{conference},
            status   => 'paid',
        );
        if ($order) {
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
            $invoice_uri{$u->user_id} = make_uri_info('invoice', $order->order_id);
            $total{ $order->currency } += $order->amount;
            $orders{$u->user_id} = $order;
        }
    }
    # sort key
    my $sortkey = $Request{args}{sort};
    $sortkey = 'user' unless $sortkey && exists $sortsub{$sortkey};

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        users       => $sortsub{$sortkey}->($users, \%orders),
        sortkey     => $sortkey,
        orders      => \%orders,
        total       => \%total,
        invoice_uri => \%invoice_uri,
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
