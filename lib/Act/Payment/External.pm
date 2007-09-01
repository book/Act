package Act::Payment::External;
use strict;
use base qw(Act::Payment::Plugin);

use DateTime;
use Digest::HMAC_SHA1;

use Act::Config;

sub create_form
{
    my ($self, $order) = @_;

    # variables submitted to the payment gateway
    my %vars = (
        date       => DateTime->now->strftime("%Y-%m-%dT%H:%M:%S"),
        amount     => $order->amount,
        currency   => $order->currency,
        orderid    => $order->order_id,
        productid  => $Request{conference},
        text       => $self->_item_name(),
        language   => $Request{language},
        returnurl  => $self->_return_url(),
    );

    # compute the digest
    $vars{MAC} = $self->_compute_digest(join '*', map $vars{$_}, sort keys %vars);

    # return the HTML form
    return $self->_process_form(
        'payment/plugins/external',
        $self->_type_config('gateway_url'),
        \%vars,
    );
}

sub verify
{
    my ($self, $args) = @_;

    my $mac = $self->_compute_digest(
        join '*',  @$args{sort qw(date amount currency orderid productid status)}
    );

    my $verified = $mac eq lc $args->{MAC};
    my $paid = $verified && $args->{'status'} eq 'paid';
    return ($verified, $paid, $args->{orderid});
}

sub create_response
{
    my ($self, $verified) = @_;

    $self->_create_response( $verified ? "OK" : "ERR forged" );
}

sub _compute_digest
{
    my ($self, $string) = @_;

    return Digest::HMAC_SHA1::hmac_sha1_hex($string, pack("H*", $self->_type_config('key')));
}

1;

__END__

=head1 NAME

Act::Payment::External - Online payment to an external gateway

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
