package Act::Payment::CyberMut;
use strict;

use Act::Config;
use Act::Order;
use Act::Util;

# CyberMut settings
use constant CM_VERSION => '1.2';
my %languages = ( fr => 'francais', en => 'anglais' );
my %submit_button = (
    fr => 'Paiement par carte bancaire',
    en => 'Credit card payment',
);

sub create_form
{
    my ($class, $order) = @_;

    require CMSSL;

    my $url = make_uri('main');
    return CMSSL::CreerFormulaireCM(
       $Config->cybermut_url_bank,
       CM_VERSION,
       $Config->cybermut_key_file,
       $order->amount,
       $order->order_id,
       '',
       $url, $url, $url,
       $languages{$Request{language}},
       $Config->cybermut_company_code,
       $submit_button{$Request{language}}
    );
}

sub verify
{
    my ($class, $args) = @_;

    require CMSSL;

    my $verified = CMSSL::TestMAC(
       $args->{MAC},
       CM_VERSION,
       $Config->cybermut_key_file,
       $args->{date},
       $args->{montant},
       $args->{reference},
       $args->{'texte-libre'},
       $args->{'code-retour'},
    );
    my $order;
    if ($verified && $args->{order_id}) {
        my $o = Act::Order->new(order_id => $args->{order_id});
        if ($o && $o->status eq 'init') {
            $order = $o;
        }
    }
    return ($verified, $order);
}

sub create_response
{
    my ($class, $verified, $order) = @_;

    # create the response to the payment notification request
    require CMSSL;
    my $response = CMSSL::CreerReponseCM($verified ? 'OK' : 'Document Falsifié');

    # we'll send the HTTP headers ourselves, thank you
    $response =~ s/^.*\n\n//s;
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
