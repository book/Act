package Act::Payment::Fake;
use strict;

use Act::Order;
use Act::Template::HTML;

sub create_form
{
    my ($class, $order) = @_;
    my $template = Act::Template::HTML->new(AUTOCLEAR => 0);
    $template->variables(order => $order);
    my $form;
    $template->process('user/fake_payment', \$form);
    return $form;
}

sub verify
{
    my ($class, $args) = @_;

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

Act::Payment::Fake - Online payment simulation

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
