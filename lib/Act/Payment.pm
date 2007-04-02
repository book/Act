package Act::Payment;
use strict;
use Act::Config;
use Act::I18N;
use Act::Util;

my @MEANS = qw(CHQ CASH ONLINE XFER);

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

sub get_price
{
    my $price_id = shift;
    my $prices = get_prices();
    for my $p (@$prices) {
        if ($p->{price_id} == $price_id) {
            return $p;
        }
    }
    return undef;
}

sub get_prices
{
    my @prices;
    for my $price_id (1..$Config->payment_prices) {
        my $s = 'price' . $price_id . '_';
        push @prices, {
            price_id => $price_id,
            amount   => $Config->get($s . 'amount'),
            name     => $Config->get($s . 'name_' . $Request{language}),
        };
    }
    return \@prices;
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
