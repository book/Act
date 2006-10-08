package Act::Payment::External;
use strict;
use base qw(Act::Payment::Plugin);

use DateTime;

use Act::Config;
use Act::Template;
use Act::Util;

sub create_form
{
    my ($self, $order) = @_;

    # variables submitted to the payment gateway
    my %vars = (
        clientid   => $self->_type_config('clientid'),
        date       => DateTime->now->strftime("%Y-%m-%dT%H:%M:%S"),
        amount     => $order->amount,
        currency   => $order->currency,
        orderid    => $order->order_id,
        category   => $Request{conference},
        language   => $Request{language},
        return_url => join('', $Request{base_url}, make_uri('main')),
    );

    # compute the digest
    $vars{MAC} = $self->_compute_digest(join '*', map $vars{$_}, sort keys %vars);

    # return the HTML form
    my $template = Act::Template->new();
    my $form;
    $template->variables(
        url  => $self->_type_config('gateway_url'),
        vars => \%vars,
    );
    $template->process('payment/form', \$form);
    return $form;
}

sub verify
{
    my ($self, $args) = @_;

    my $mac = $self->_compute_digest(
        join '+', $self->_type_config('clientid'),
                  @$args{sort qw(date amount currency orderid category status)},
    );
    my $verified = $mac eq lc $args->{MAC};
    my $paid = $verified && $args->{'status'} eq 'paid';
    return ($verified, $paid, $args->{orderid});
}

sub create_response
{
    my ($self, $verified) = @_;

    my $response = $verified ? "OK" : "ERR forged";
    $Request{r}->print(<<EOF);
Pragma: no-cache
Content-type: text/plain
Version: 1
$response
EOF
}

sub _compute_digest
{
    my ($self, $string) = @_;

    require Digest::HMAC_SHA1;
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
