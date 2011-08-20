package Act::Handler;
use strict;
use warnings;

use parent 'Plack::Component';
use Act::Config;
use Act::Util;
use Act::I18N;
use Act::Request;
use Plack::Util::Accessor qw(private);

sub call {
    my $self = shift;
    my $env = shift;
    my $req = Act::Request->new($env);
    my $handler = $self->can('handler');
    %Request = (
        r           => $req,
        path_info   => $req->path_info,
        base_url    => $env->{'act.base_url'},
        conference  => $env->{'act.conference'},
        private     => $self->private,
        args        => { map { scalar $_ => decode_utf8($r->param($_)) } $r->param };
        language    => $env->{'act.language'},
        loc         => Act::I18N->get_handle($env->{'act.language'}),
    );
    $Config = $env->{'act.config'};

    $handler->($env);
}

1;
__END__

=head1 NAME

Act::Handler - parent class for Act handlers

=cut

