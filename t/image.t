use strict;
use Act::Config;
use Imager;
use Test::More;

plan tests => 2 + scalar keys %Act::Config::Image_formats;

for my $f (keys %Act::Config::Image_formats) {
    ok(exists $Imager::formats{$f}, "$f is handled by Imager");
}

my ($w, $h) = split /\D+/, $Config->general_max_imgsize;
ok($w, "max width is $w");
ok($h, "max height is $h");

__END__
