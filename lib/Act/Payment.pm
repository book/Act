package Act::Payment;
use strict;
use Act::Config;

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
