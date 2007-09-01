package Act::Payment::CyberMut;
use strict;
use base qw(Act::Payment::Plugin);

use DateTime;
use Digest::HMAC_SHA1;

use Act::Config;
use Act::Util;

# CyberMut settings
my $Version  = '1.2open';
my %Languages = map { $_ => 1 } qw(DE EN ES FR IT);

sub create_form
{
    my ($self, $order) = @_;

    # language
    my $langue   = uc $Request{language};
    $langue = 'EN' unless exists $Languages{$langue}; 

    # variables submitted to the bank
    my %vars = (
        version         => $Version,
        TPE             => $self->_type_config('tpe'),
        date            => DateTime->now->set_time_zone('Europe/Paris')->strftime("%d/%m/%Y:%H:%M:%S"),
        montant         => $order->amount . $order->currency,
        reference       => $order->order_id,
        url_retour      => $self->_return_url(),
        url_retour_ok   => $self->_return_url(),
        url_retour_err  => $self->_return_url(),
        lgue            => $langue,
        societe         => $self->_type_config('societe'),
        "texte-libre"   => $Request{conference},
    );

    # compute the Digest
    my $key     = pack("H*", $self->_type_config('key'));
    my $hstring = join("*", @vars{qw(TPE date montant reference), 'texte-libre', qw(version lgue societe)}) . "*";
    $vars{MAC}  = Digest::HMAC_SHA1::hmac_sha1_hex($hstring, $key);

    # return the HTML form
    return $self->_process_form(
        'payment/plugins/cybermut',
        $Config->payment_plugin_CyberMut_url_bank,
        \%vars,
    );
}

sub verify
{
    my ($self, $args) = @_;

    require Digest::HMAC_SHA1;

    my $hstring = $args->{retourPLUS}
                . join("+", $self->_type_config('tpe'),
                            $args->{date}, $args->{montant}, $args->{reference}, $args->{'texte-libre'},
                            $Version,
                            $args->{'code-retour'},
                       )
                . "+";
    my $mac = Digest::HMAC_SHA1::hmac_sha1_hex($hstring, pack("H*", $self->_type_config('key')));
    my $verified = $mac eq lc $args->{MAC};
    my $paid = $verified && $args->{'code-retour'} =~ /^payetest|paiement$/;
    return ($verified, $paid, $args->{reference});
}

sub create_response
{
    my ($self, $verified) = @_;

    $self->_create_response( $verified ? "OK" : "Document falsifie" );
}

1;

__END__

=head1 NAME

Act::Payment::CyberMut - Online payment using CyberMut

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
