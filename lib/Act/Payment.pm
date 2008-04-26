package Act::Payment;
use strict;

use List::Util qw(first);

use Act::Config;
use Act::I18N;
use Act::Util;

my @MEANS = qw(CHQ CASH XFER FREE);

# load appropriate payment plugin
sub load_plugin
{
    my $type = shift || $Config->payment_type;

    # get plugin name
    my $name = $Config->get("payment_type_${type}_plugin");

    # require new plugin
    my $class = join '::', qw(Act Payment), $name;
    eval "require $class";
    die "require $class failed!" if $@;

    # instantiate
    return $class->new($type);
}

sub get_prices
{
    my @products = split /\s+/, $Config->payment_products;
    my %products;
    for my $p (@products) {
        my $s = 'product_' . $p . '_';

        # get prices
        my $nprices = $Config->get($s . 'prices');
        my @prices;
        for my $price_id (1..$nprices) {
            my $t = $s . 'price' . $price_id . '_';
            push @prices, {
                price_id => $price_id,
                amount   => $Config->get($t . 'amount'),
                name     => Act::Config::get_optional($t . 'name_' . $Request{language}),
                promocode => Act::Config::get_optional($t . 'promocode'),
            };
        }
        $products{$p} = {
            name    => $Config->get($s . 'name_' . $Request{language}),
            prices  => \@prices,
        };
    }
    return (\@products, \%products);
}

sub get_means
{
    my $lh = Act::I18N->get_handle($Request{language});
    return { map { $_ => $lh->maketext("payment_means_$_") } @MEANS };
}

1;

__END__

=head1 NAME

Act::Payment - Online payment routines

=head1 SYNOPSIS

    use Act::Payment;

    my $plugin = Act::Payment::load_plugin();
    my $form = $plugin->create_form(
        order_id => $order_id,
        amount   => $Config->payment_amount,
    );
    my $prices = Act::Payment::get_prices();

=cut
