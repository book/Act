use strict;
package Act::Dispatcher;

use vars qw(@ISA @EXPORT $Config %Request);
@ISA    = qw(Exporter);
@EXPORT = qw($Config %Request);

use Apache::Constants qw(OK DECLINED);
use AppConfig qw(:expand :argcount);

# load global configuration
_load_global_config();

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
    my $r = shift;

    # we're looking for /x/y where
    # x is a conference name, and
    # y is an action key in %dispatch
    my @c = grep $_, split '/', $r->uri;
    if (   @c >= 2
        && exists $Config->conferences->{$c[0]}
        && exists $dispatch{$c[1]}
       )
    {
        # initialize our per-request variables
        %Request = (
            conference => $c[0],
            action     => $c[1],
        );
        $r->push_handlers(PerlHandler => 'Act::Dispatcher::handler');
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

# load global configuration
sub _load_global_config
{
    my $home = $ENV{ACTHOME} or die "ACTHOME environment variable isn't set\n";
    $Config = AppConfig->new(
         {
            CREATE => 1,
            GLOBAL => {
                   DEFAULT  => "<undef>",
                   ARGCOUNT => ARGCOUNT_ONE,
                   EXPAND   => EXPAND_VAR,
               }
         }
    );
    $Config->set(home => $home);
    $Config->file(map "$home/conf/$_.ini", qw(act local));
    $Config->set(conferences => { map { $_ => 1 } split /\s+/, $Config->general_conferences });
}
1;
