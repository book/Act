use strict;
use warnings;
use Test::Lib;
use lib 'lib';

use FindBin;
use Path::Tiny;
use Test::More;

my $dir = path('lib/');
my $iter = $dir->iterator({recurse => 1, follow_symlinks => 0});

while (my $path = $iter->()) {
    next if $path->is_dir || $path !~ /\.pm$/;

    my $module = $path->relative;
    $module =~ s/(?:^lib\/|\.pm$)//g;
    $module =~ s/\//::/g;
    BAIL_OUT( "$module does not compile" ) unless require_ok( $module );
}

done_testing;
