use strict;
package Act::Util;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw(make_uri self_uri);

use Crypt::RandPasswd ();
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

sub gen_password
{
   my $clear_passwd = Crypt::RandPasswd->letters( 7, 7 );
   my $crypt_passwd = crypt( $clear_passwd, '/' );
   return ($clear_passwd, $crypt_passwd);
}

1;

__END__

=head1 NAME

Act::Util - Utility routines

=head1 SYNOPSIS

    make_uri("talkview", id => 234, name => 'foo');
    self_uri(language => 'en');

=head1 DESCRIPTION

Act::Util contains a collection of utility routines that didn't fit anywhere
else.

=over 4

=item make_uri(I<$action>, I<%params>)

Returns an URI that points to I<action>, with an optional query string
built from I<%params>. For more details on actions, refer to the
Act::Dispatcher documentation.

=item self_uri(I<%params>)

Returns a self-referential URI (a URI that points to the current location)
with an optional query string built from I<%params>. 

=back

=cut
