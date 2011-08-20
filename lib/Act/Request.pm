package Act::Request;

use strict;
use warnings;
use parent 'Plack::Request';

use Plack::Util::Accessor qw(response);

sub new {
    my ( $class ) = @_;

    my $self = Plack::Request::new(@_);

    $self->response($self->new_response);

    return $self;
}

sub act_user {
    my ( $self ) = @_;
}

sub no_cache {
    my ( $self, $dont_cache ) = @_;

    if($dont_cache) {
        $self->response->header('Cache-Control' => 'no-cache');
        $self->response->header('Pragma'        => 'no-cache');
    }
}

1;

__END__

=head1 NAME

Act::Request - A subclass of Plack::Request that handles like Apache::Request

=head1 DESCRIPTION

=cut
