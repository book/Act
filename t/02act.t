#!perl -w
use strict;
use Test::More;
use File::Find;

my @modules;

find( sub {
          return unless /\.pm/; local $_ = $File::Find::name;
          s!/!::!g; s/^lib/Act/; s/\.pm$//;
          push @modules, $_;
      }, 'lib' );

plan tests => scalar(@modules);

# Apache::Constants only works under mod_perl
package Apache::Constants;
use constant OK       =>  0;
use constant DECLINED => -1;
use constant DONE     => -2;

package main;
require_ok($_) for @modules;
