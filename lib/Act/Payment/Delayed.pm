package Act::Payment::Delayed;
use strict;
use base qw(Act::Payment::Plugin);

use Act::Config;
use Act::Util;

sub create_form
{
    my ($self, $order) = @_;

    # return the HTML form
    return $self->_process_form(
        'payment/plugins/delayed',
        '/confirm_delayed',
        {
            order_id    => $order->order_id,
            amount      => $order->amount,
        }
    );
}

sub verify
{
    my ($self, $args) = @_;
    return (1, 1, $args->{order_id});
}

sub create_response
{
    my ($self, $verified, $order) = @_;

    # we aren't being dispatched by Act::Dispatcher
    $Config = Act::Config::get_config($Request{conference} = $order->conf_id);

    # back to the user's main page
    Act::Util::redirect(make_uri('main'));
}

1;

__END__

=head1 NAME

Act::Payment::Delayed - Online delayed payment

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
