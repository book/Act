package Act::Payment::Plugin;
use strict;

use Act::Config;

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

1;

__END__

=head1 NAME

Act::Payment::Plugin - base class for payment plugins

=head1 DESCRIPTION

This class is loaded automatically according to the
current configuration.
Refer to L<Act::Payment> for details.

=cut
