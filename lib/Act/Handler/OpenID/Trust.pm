package Act::Handler::OpenID::Trust;

use strict;
use parent 'Act::Handler';
use Act::Config;
use Act::Util;
use URI::Escape;

sub handler {
    ## We're logged in, so just redirect, until we have actual trusting.
    my $uri = $Request{base_url} . make_uri('openid') . '?openid.mode=checkid_setup&openid.identity=';
    $uri .= URI::Escape::uri_escape($Request{args}{identity});
    $uri .= '&openid.return_to=';
    $uri .= URI::Escape::uri_escape($Request{args}{return_to});
    $uri .= '&openid.trust_root=';
    $uri .= URI::Escape::uri_escape($Request{args}{trust_root});

    Act::Util::redirect($uri);
}

1;
