use Test::More;
use File::Find;

my @files;
find( sub { push @files, $File::Find::name if /\.p(?:m|od)$/ }, 'lib' );

plan tests => scalar @files;

SKIP: {
    eval { require Test::Pod; import Test::Pod; };
    skip "Test::Pod not available", scalar @files if $@;
    if ( $Test::Pod::VERSION >= 0.95 ) {
        pod_file_ok($_) for @files;
    }
    else {
        pod_ok($_) for @files;
    }
}

