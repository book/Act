use strict;
package Act::Config;

use vars qw(@ISA @EXPORT $Config %Request);
@ISA    = qw(Exporter);
@EXPORT = qw($Config %Request);

use AppConfig qw(:expand :argcount);

# load global configuration
sub load_global_config
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
