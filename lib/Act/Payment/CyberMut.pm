package Act::Payment::CyberMut;
use strict;

use DateTime;

use Act::Config;
use Act::Order;
use Act::Util;

# CyberMut settings
my $Version  = '1.2open';
my %Submit_button = (
    FR => 'Paiement par carte bancaire',
    EN => 'Credit card payment',
);

sub create_form
{
    my ($class, $order) = @_;

    require Digest::HMAC_SHA1;

    my $url_bank = $Config->cybermut_url_bank;
    my $url_main = join('/', $Request{base_url}, make_uri('main'));
    my $key      = pack("H*", $Config->cybermut_key);
    my $date     = DateTime->now->strftime("%d/%m/%Y:%H:%M:%S");
    my $tpe      = $Config->cybermut_tpe;
    my $societe  = $Config->cybermut_societe;
    my $montant  = $order->amount . $order->currency;
    my $langue   = uc $Request{language};
    $langue = 'EN' unless $langue eq 'FR';
    my $ref      = $order->order_id;
    my $txt      = '';

    my $hstring = join("*", $tpe, $date, $montant, $ref, $txt, $Version, $langue, $societe) . "*";
    my $mac = Digest::HMAC_SHA1::hmac_sha1_hex($hstring, $key);

    return <<EOF
<FORM  METHOD="post" NAME="FinalOrder" ACTION="$url_bank">
<INPUT TYPE="hidden" NAME="version"        VALUE="$Version" />
<INPUT TYPE="hidden" NAME="TPE"            VALUE="$tpe" />
<INPUT TYPE="hidden" NAME="date"           VALUE="$date" />
<INPUT TYPE="hidden" NAME="montant"        VALUE="$montant" />
<INPUT TYPE="hidden" NAME="reference"      VALUE="$ref" />
<INPUT TYPE="hidden" NAME="MAC"            VALUE="$mac" />
<INPUT TYPE="hidden" NAME="url_retour"     VALUE="$url_main" />
<INPUT TYPE="hidden" NAME="url_retour_ok"  VALUE="$url_main" />
<INPUT TYPE="hidden" NAME="url_retour_err" VALUE="$url_main" />
<INPUT TYPE="hidden" NAME="lgue"           VALUE="$langue" />
<INPUT TYPE="hidden" NAME="societe"        VALUE="$societe" />
<INPUT TYPE="hidden" NAME="texte-libre"    VALUE="$txt" />
<INPUT TYPE="submit" NAME="bouton"         VALUE="$Submit_button{$langue}" />
</FORM>
EOF
}

sub verify
{
    my ($class, $args) = @_;

    require Digest::HMAC_SHA1;

    my $hstring = $args->{retourPLUS}
                . join("+", $Config->cybermut_tpe,
                            $args->{date}, $args->{montant}, $args->{reference}, $args->{'texte-libre'},
                            $Version,
                            $args->{'code-retour'},
                       )
                . "+";
    my $mac = Digest::HMAC_SHA1::hmac_sha1_hex($hstring, pack("H*", $Config->cybermut_key));
    my $verified = $mac eq lc $args->{MAC};
    my $paid = $verified && $args->{'code-retour'} =~ /^payetest|paiement$/;
    return ($verified, $paid, $args->{reference});
}

sub create_response
{
    my ($class, $verified) = @_;

    my $response = $verified ? "OK\n" : "Document falsifie\n";
    $Request{r}->no_cache(1);
    $Request{r}->send_http_header( 'text/plain' );
    $Request{r}->print($response);
}

1;

__END__

=head1 NAME

Act::Payment::CyberMut - Online payment simulation

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
