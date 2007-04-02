package Act::Handler::Payment::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Invoice;
use Act::Order;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    # for treasurers only
    unless ($Request{user} && $Request{user}->is_treasurer) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # retrieve users and their payment info
    my $users = Act::User->get_items( conf_id => $Request{conference} );
    my (%orders, %invoice_uri);
    for my $u (@$users) {
        $orders{$u->user_id} = Act::Order->new(
            user_id  => $u->user_id,
            conf_id  => $Request{conference},
            status   => 'paid',
        );
        if ($orders{$u->user_id}) {
            $orders{$u->user_id}{means} = localize('payment_means_' . $orders{$u->user_id}{means});
            if (my $i = Act::Invoice->new(order_id => $orders{$u->user_id}->order_id)) {
                $invoice_uri{$u->user_id} = make_uri_info('invoice', $i->order_id);
            }
        }
    }

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        users => [ sort {
                            lc $a->last_name  cmp lc $b->last_name
                         || lc $a->first_name cmp lc $b->first_name
                        }
                   @$users
                 ],
        orders => \%orders,
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
