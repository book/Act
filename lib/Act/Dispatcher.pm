use strict;
package Act::Dispatcher;

use vars qw(@ISA @EXPORT $Config);
@ISA    = qw(Exporter);
@EXPORT = qw($Config);

use Apache::Constants qw(OK DECLINED);
use AppConfig qw(:expand :argcount);

# load global configuration
_load_global_config();

# main dispatch table
my %dispatch = (
    coucou => sub {
        $Config->r->send_http_header('text/plain');
        $Config->r->print("conférence ", $Config->conference);
    },
);

# translation handler
sub trans_handler
{
    my $r = shift;
    my @c = grep $_, split '/', $r->uri;

    if (   @c >= 2
        && exists $Config->conferences->{$c[0]}
        && exists $dispatch{$c[1]}
       )
    {
        $Config->set(conference => $c[0]);
        $Config->set(action     => $c[1]);
        $r->push_handlers(PerlHandler => 'Act::Dispatcher::handler');
        return OK;
    }
    return DECLINED;
}

# response handler - it all starts here.
sub handler
{
    # the Apache request object
    $Config->set(r => shift);

    # dispatch
    $dispatch{$Config->action}->();

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
