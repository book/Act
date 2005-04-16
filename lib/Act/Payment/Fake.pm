package Act::Payment::Fake;
use strict;

use Act::Config;
use Act::Order;
use Act::Template::HTML;
use Act::Util;

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
            return (1, $order);
        }
    }
    return (1, undef);
}

sub create_response
{
    my ($class, $verified, $order) = @_;

    # we aren't being dispatched by Act::Dispatcher
    $Config = Act::Config::get_config($Request{conference} = $order->conf_id);

    # back to the user's main page
    Act::Util::redirect(make_uri('main'));
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
