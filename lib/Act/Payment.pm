package Act::Payment;
use strict;
use Act::Config;
use Act::Util;

my %Plugins;

# load appropriate payment plugin
sub load_plugin
{
    my $name = shift || $Config->payment_type;

    # return new plugin if not already in cache
    unless (exists $Plugins{$name}) {

        # require new plugin
        my $class = join '::', qw(Act Payment), $name;
        eval "require $class";
        die "require $class failed!" if $@;

        # instantiate
        $Plugins{$name} = $class->new();
    }
    return $Plugins{$name};
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
            currency => $Config->get($s . 'currency'),
            name     => Act::Util::get_translation('prices', 'name', $Config->get($s . 'type')),
        };
    }
    return \@prices;
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

=cut
