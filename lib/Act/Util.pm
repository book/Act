use strict;
package Act::Util;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw(make_uri self_uri);

use URI::Escape ();
use Act::Config;

# create a uri for an action with args
sub make_uri
{
    my ($action, %params) = @_;

    my $uri = $Request{conference}
            ? "/$Request{conference}/$action"
            : "/$action";
    return _build_uri($uri, %params);
}

# self-referential uri with new args
sub self_uri
{
    return _build_uri($Request{r}->uri, @_);
}

sub _build_uri
{
    my ($uri, %params) = @_;

    if (%params) {
        $uri .= '?'
             . join '&',
               map "$_=" . URI::Escape::uri_escape($params{$_}),
               sort keys %params;
    }
    return $uri;
}

1;

__END__
