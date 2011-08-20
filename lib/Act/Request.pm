package Act::Request;

use strict;
use warnings;
use parent 'Plack::Request';

use Plack::Util::Accessor qw(response _body);

sub new {
    my ( $class ) = @_;

    my $self = Plack::Request::new(@_);

    $self->_body([]);
    $self->response($self->new_response(200, [], $self->_body));

    return $self;
}

sub no_cache {
    my ( $self, $dont_cache ) = @_;

    if($dont_cache) {
        $self->response->header('Cache-Control' => 'no-cache');
        $self->response->header('Pragma'        => 'no-cache');
    }
}

sub print {
    my $self = shift;

    push @{ $self->_body }, @_;
}

sub auth_type {
    my ( $self ) = @_;
}

sub send_http_header {
    my ( $self, $content_type ) = @_;

    return unless $content_type;

    $self->response->content_type($content_type);
}

sub upload {
    my ( $self ) = @_;

    # XXX returned value must support fh method (return psgi.input? but that only supports readline...)
}

1;

__END__

=head1 NAME

Act::Request - A subclass of Plack::Request that handles like Apache::Request

=head1 DESCRIPTION

=cut
