package Act::Payment::Paypal;
use strict;
use base qw(Act::Payment::Plugin);

use HTTP::Request::Common;
use LWP::UserAgent;
use IPC::Open2;

use Act::Config;

sub create_form
{
    my ($self, $order) = @_;

    # variables submitted to Paypal
    my %vars = (
        cmd             => '_xclick',
        business        => $self->_type_config('email'),
        item_name       => $self->_item_name(),
        item_number     => $order->order_id,
        amount          => $order->amount,
        currency_code   => $order->currency,
        notify_url      => join('', $Request{base_url}, '/', $self->{type}, 'confirm'),
        return          => $self->_return_url(),
        cancel_return   => $self->_return_url(),
        rm              => '1',
        no_note         => '1',
        no_shipping     => '0',
        charset         => 'utf-8',
        'lc'            => uc($Request{user}->country) || 'US',
    );

    # encrypt and sign
    my $encrypted = $self->_encrypt_and_sign(%vars);

    # return the HTML form
    return $self->_process_form(
        'payment/plugins/paypal',
        $Config->payment_plugin_Paypal_url_bank,
        {
            cmd       => "_s-xclick",
            encrypted => $encrypted,
        }
    );
}

sub verify
{
    my ($self, $args) = @_;

    # fetch global config
    my $config = Act::Config::get_config();
    my $url_bank = $Config->payment_plugin_Paypal_url_bank;

    # post back to PayPal system to validate
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request(
        POST $url_bank,
            [ cmd  => '_notify-validate',
              %$args,
            ]
    );
    my $verified = $res->content eq 'VERIFIED';
    my $order_id = $args->{item_number};
    my $paid     = $args->{payment_status} eq 'Completed';

    if ($res->is_error) {
        warn "error acking Paypal IPN: " . $res->as_string;
    }
    elsif ($res->content eq 'INVALID') {
        warn "received INVALID PayPal IPN for order $order_id\n";
    }
    return ($verified, $paid, $order_id);
}

sub create_response
{
    my ($self, $verified) = @_;

    $self->_create_response( '' );
}

sub _encrypt_and_sign
{
    my ($self, %form) = @_;

    my $openssl = $Config->payment_plugin_Paypal_openssl;
    my $pp_cert = $Config->payment_plugin_Paypal_pp_cert;
    my $my_cert = $self->_type_config('my_cert');
    my $my_key  = $self->_type_config('my_key');
    $form{cert_id} = $self->_type_config('my_cert_id');

    my $pid = open2(*READER, *WRITER,
                    "$openssl smime -sign -signer $my_cert"
                  . " -inkey $my_key -outform der -nodetach -binary"
                  . " | $openssl smime -encrypt -des3 -binary -outform pem $pp_cert"
                  )
        or die "error open2 $openssl: $!\n"; 
    
    while (my ($key, $value) = each %form) {
        print WRITER "$key=$value\n";
    }
    close(WRITER);
    my @lines = <READER>;
    close(READER);
    my $encrypted = join('', @lines);
    $encrypted =~ s/\n//g;
    return $encrypted;
}

1;

__END__

=head1 NAME

Act::Payment::Paypal - Online payment using Paypal

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
