package Act::Payment::CyberMut;
use strict;

use Act::Config;
use Act::Order;
use Act::Template::HTML;

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

    return CMSSL::CreerFormulaireCM(
       $Config->cybermut_url_bank,
       CM_VERSION,
       $Config->cybermut_key_file,
       $order->amount,
       $order->order_id,
       '',
       $Config->cybermut_url_home,
       $Config->cybermut_url_ok,
       $Config->cybermut_url_error,
       $languages{$Request{language}},
       $Config->cybermut_company_code,
       $submit_button{$Request{language}}
    );
}

sub verify
{
    my ($class, $args) = @_;

    my $verified = CMSSL::TestMAC(
       $args->{MAC},
       CM_VERSION,
       $YAPC::Globals::Payment_key_file,
       $args->{date},
       $args->{montant},
       $args->{reference},
       $args->{'texte-libre'},
       $args->{'code-retour'},
    );
    if ($args->{order_id}) {
        my $order = Act::Order->new(order_id => $args->{order_id});
        if ($order && $order->status eq 'init') {
            return $order;
        }
    }
    return undef;
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
