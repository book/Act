package Act::Payment::Plugin;
use strict;

use Act::Config;
use Act::Template::HTML;
use Act::Util;

sub new
{
    my ($class, $type) = @_;
    bless { type => $type }, $class;
}
sub _type_config
{
    my ($self, $key) = @_;
    return $Config->get(join '_', 'payment_type', $self->{type}, $key);
}
sub _return_url
{
    my $self = shift;
    return join('', $Request{base_url}, make_uri('main'));
}
sub _item_name
{
    my $self = shift;
    return localize('<conf> registration', $Config->name->{$Request{language}}),
}
sub _process_form
{
    my ($self, $template_name, $url, $vars) = @_;

    my $template = Act::Template::HTML->new();
    $template->variables(
        url  => $url,
        vars => $vars,
    );
    my $form;
    $template->process($template_name, \$form);
    return $form;
}
sub _create_response
{
    my ($self, $response) = @_;

    $Request{r}->print(<<EOF);
Pragma: no-cache
Content-type: text/plain
Version: 1
$response
EOF
}

1;

__END__

=head1 NAME

Act::Payment::Plugin - base class for payment plugins

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
