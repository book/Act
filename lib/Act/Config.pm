use strict;
package Act::Config;

use vars qw(@ISA @EXPORT $Config %Request);
@ISA    = qw(Exporter);
@EXPORT = qw($Config %Request);

use AppConfig qw(:expand :argcount);

# load global configuration
load_global_config();

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

    # some prefs are useful as hash keys
    _make_hash(conferences => $Config->general_conferences,
               languages   => $Config->general_languages,
    );
}

sub _make_hash
{
    my %h = @_;
    while (my ($key, $value) = each %h) {
        $Config->set($key => { map { $_ => 1 } split /\s+/, $value });
    }
}
1;
