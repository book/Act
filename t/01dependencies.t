#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.

=cut

use Test::More 0.96;
use File::Find;
use version;

eval 'use Module::CoreList';
if ($@) { plan skip_all => 'Module::CoreList not installed' }

my %used;
find( \&wanted, qw/ lib t / );

sub wanted {
    return unless -f $_;
    return if $File::Find::dir  =~ m!/.svn($|/)!;
    return if $File::Find::name =~ /~$/;
    return if $File::Find::name =~ /\.(pod|html)$/;

    # read in the file from disk
    my $filename = $_;
    local $/;
    open( FILE, $filename ) or return;
    my $data = <FILE>;
    close(FILE);

    # strip pod, in a really idiotic way.  Good enough though
    $data =~ s/^=head.+?(^=cut|\Z)//gms;

    # look for use and use base statements
    $used{$1}{$File::Find::name}++ while $data =~ /^\s*use\s+([\w:]+)/gm;
    while ( $data =~ m|^\s*use base qw.([\w\s:]+)|gm ) {
        $used{$_}{$File::Find::name}++ for split ' ', $1;
    }
}

my %required;
{
    local $/;
    ok( open( MAKEFILE, "Makefile.PL" ), "Opened Makefile.PL" );
    my $data = <MAKEFILE>;
    close(FILE);
    while ( $data =~ /^\s*?(?:requires|recommends|).*?([\w:]+)'(?:\s*=>\s*['"]?([\d\._]+)['"]?).*?(?:#(.*))?$/gm ) {
        $required{$1} = $2;
        if ( defined $3 and length $3 ) {
            $required{$_} = undef for split ' ', $3;
        }
    }
}

for ( sort keys %used ) {
    my $first_in = Module::CoreList->first_release($_);
    next if defined $first_in and $first_in <= 5.00803;
    next if /^(Act|inc|Test::Act)(::|$)/;

    #warn $_;
    ok( exists $required{$_}, "$_ in Makefile.PL" )
        or diag( "used in ", join ", ", sort keys %{ $used{$_} } );
}

for (sort keys %required) {
    my $first_in = Module::CoreList->first_release($_, $required{$_});
    fail("Required module $_ (v. $required{$_}) is in core since $first_in")
        if defined $first_in and $first_in <= 5.008003;
    if (require_ok($_)) {
        if (defined $required{$_}) {
            my $version = eval '$' . $_ . '::VERSION';
            next unless $version;
            cmp_ok(
                version->new($version),
                'ge',
                version->new($required{$_}),
                "$_ v. $version >= $required{$_}"
            );
        }
    }
    else {
        fail("$_ (v. $required{$_}) not installed, version check failed");
    }
}

done_testing;

1;

