package Act::Handler::Payment::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Invoice;
use Act::Order;
use Act::Template::HTML;
use Act::User;

sub handler
{
    # for treasurers only
    unless ($Request{user} && $Request{user}->is_treasurer) {
        $Request{status} = NOT_FOUND;
        return;
    }
    # retrieve users and their payment info
    my $users = Act::User->get_items( conf_id => $Request{conference} );
    my %orders;
    for my $u (@$users) {
        $orders{$u->user_id} = Act::Order->new(
            user_id  => $u->user_id,
            conf_id  => $Request{conference},
            status   => 'paid',
        );
    }
    # set/unset invoice_ok
    if ($Request{args}{ok}) {
        for my $o (grep defined($_), values %orders) {
            if ($o->invoice_ok && !$Request{args}{$o->order_id}) {
                $o->update(invoice_ok => 0);
            }
            elsif (!$o->invoice_ok && $Request{args}{$o->order_id}) {
                $o->update(invoice_ok => 1);
                # create invoice if it doesn't exist
                my $invoice = Act::Invoice->new(order_id => $o->order_id);
                unless ($invoice) {
                    my $u = Act::User->new(user_id => $o->user_id);
                    Act::Invoice->create(
                        order_id  => $o->order_id,
                        # order info
                        amount      => $o->amount,
                        currency    => $o->currency,
                        means       => $o->means,
                        # user info
                        first_name  => $u->first_name,
                        last_name   => $u->last_name,
                        # billing info
                        company     => $u->company,
                        company_url => $u->company_url,
                        address     => $u->address,
                    );
                }
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
