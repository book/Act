#!perl -w
use strict;
use Test::More;
use File::Find;

my @modules;

find( sub {
          return unless /\.pm/; local $_ = $File::Find::name;
          s!/!::!g; s/^lib/Act/; s/\.pm//;
          push @modules, $_;
      }, 'lib' );

plan tests => scalar(@modules);

require_ok($_) for @modules;
