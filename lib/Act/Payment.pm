package Act::Payment;
use strict;
use Act::Config;
use Act::Util;

our $AUTOLOAD;

sub AUTOLOAD
{
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
    return if $method eq "DESTROY";

    # load appropriate payment backend class
    my $class = join '::', qw(Act Payment), $Config->payment_type;
    eval "require $class";
    die "require $class failed!" if $@;

    # class methods only here
    shift;

    # we create the function here so that it will not need to be
    # autoloaded the next time.
    no strict 'refs';
    *$method = eval "sub { $class->$method(\@_) }";
    $class->$method(@_);
}

sub get_price
{
    my $price_id = shift;
    my $sth = $Request{dbh}->prepare_cached(
                'SELECT amount, currency FROM prices WHERE conf_id=? AND price_id=?');
    $sth->execute($Request{conference}, $price_id);
    my ($amount, $currency) = $sth->fetchrow_array();
    $sth->finish;
    return $amount
         ? { 
            price_id => $price_id,
            amount   => $amount,
            currency => $currency,
            name     => Act::Util::get_translation('prices', 'name', $price_id),
           }
         : undef;
}

sub get_prices
{
    my $sth = $Request{dbh}->prepare_cached(
                'SELECT price_id, amount, currency FROM prices WHERE conf_id=? ORDER BY price_id');
    $sth->execute($Request{conference});
    my @prices;
    while (my ($price_id, $amount, $currency) = $sth->fetchrow_array()) {
        push @prices, {
            price_id => $price_id,
            amount   => $amount,
            currency => $currency,
            name     => Act::Util::get_translation('prices', 'name', $price_id),
        };
    }
    $sth->finish;
    return \@prices;
}

1;

__END__

=head1 NAME

Act::Payment - Online payment routines

=head1 SYNOPSIS

    use Act::Payment;

    my $form = Act::Payment->create_form(
        order_id => $order_id,
        amount   => $Config->payment_amount,
    );

=cut
