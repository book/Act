use strict;
package Act::Dispatcher;

use Apache::Constants qw(OK DECLINED);

use Act::Config;

# load global configuration
Act::Config::load_global_config();

# main dispatch table
my %dispatch = (
    coucou => sub {
        $Request{r}->send_http_header('text/plain');
        $Request{r}->print("conférence ", $Request{conference});
    },
);

# translation handler
sub trans_handler
{
    # the Apache request object
    my $r = shift;

    # break it up in components
    my @c = grep $_, split '/', $r->uri;

    # initialize our per-request variables
    %Request = (
        r         => $r,
        path_info => join('/', @c),
    );

    # see if URI starts with a conf name
    if (@c && exists $Config->conferences->{$c[0]}) {
        $Request{conference} = shift @c;
        $Request{path_info}  = join '/', @c;
    }
    # pseudo-static pages
    if ($r->uri =~ /\.html$/) {
        $r->push_handlers(PerlHandler => 'Act::Static');
        return OK;
    }
    # we're looking for /x/y where
    # x is a conference name, and
    # y is an action key in %dispatch
    if (@c && $Request{conference} && exists $dispatch{$c[0]}) {
        $Request{action}     = shift @c;
        $Request{path_info}  = join '/', @c;
        $r->push_handlers(PerlHandler => 'Act::Dispatcher');
        return OK;
    }
    return DECLINED;
}

# response handler - it all starts here.
sub handler
{
    # the Apache request object
    $Request{r} = shift;

    # dispatch
    $dispatch{$Request{action}}->();

    return OK;
}
1;
