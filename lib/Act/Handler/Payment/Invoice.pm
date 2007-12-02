package Act::Handler::Payment::Invoice;
use strict;

use Apache::Constants qw(NOT_FOUND FORBIDDEN);

use Act::Config;
use Act::Form;
use Act::User;
use Act::Invoice;
use Act::Order;
use Act::Template::HTML;
use Act::Util;

my $form = Act::Form->new(
  required => [qw(first_name last_name address)],
  optional => [qw(company vat)],
);

sub handler
{
    # invoices must be enabled
    unless ($Config->payment_invoices || $Request{user}->is_treasurer) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # retrieve order_id
    my $order_id = $Request{path_info} || $Request{args}{order_id};
    unless ($order_id =~ /^\d+$/) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # get the order
    my $order   = Act::Order->new(   order_id => $order_id );
    unless ($order) {
        $Request{status} = NOT_FOUND;
        return;
    }

    # only a treasurer or the client can see the invoice
    unless ($Request{user}->user_id == $order->user_id || $Request{user}->is_treasurer) {
        $Request{status} = FORBIDDEN;
        return;
    }

    # get the invoice
    my $template = Act::Template::HTML->new();
    my $invoice = Act::Invoice->new( order_id => $order_id );

    # invoice doesn't exist
    unless ($invoice) {
        my $fields;
        my $user = Act::User->new(user_id => $order->user_id);

        # user confirms billing info
        if ($Request{args}{ok}) {
            # form has been submitted
            my @errors;
    
            # validate form fields
            my $ok = $form->validate($Request{args});
            $fields = $form->{fields};

            if ($ok) {
                # update user
                $user->update(%$fields);

                # create invoice
                $invoice = Act::Invoice->create(
                    (map { $_ => $order->$_ } qw(order_id amount currency means)),
                    (map { $_ => $user->$_ }  qw(first_name last_name company vat address)),
                );
                # redirect to canonical invoice URL
                return Act::Util::redirect(make_uri_info('invoice', $order_id));
            }
            else {
                # map errors
                $form->{invalid}{first_name} && push @errors, 'ERR_FIRST_NAME';
                $form->{invalid}{last_name}  && push @errors, 'ERR_LAST_NAME';
                $form->{invalid}{address}    && push @errors, 'ERR_ADDRESS';
            }
            $template->variables(errors => \@errors);
        }
        else {
            $fields = {%{$user}};
            $user->address or $template->variables(errors => [ 'ERR_ADDRESS' ]);
        }
        # display billing info confirmation form
        $template->variables(
            order_id => $order_id,
            %$fields,
        );
        $template->process('payment/confirm_invoice');
        return;
    }

    # process the template
    $order->{means} = localize('payment_means_' . $order->means);
    $template->variables(
        order   => $order,
        invoice => $invoice,
        today   => DateTime->now,
        printer_friendly => $Request{args}{printer},
        printer_uri      => self_uri(printer => 1),
    );
    $template->process('payment/invoice');
}

1;

