#!perl -w

use strict;
use Test::More tests => 50;

my @tests = (
{ profile => {
      required => [ qw(r1 r2) ],
      optional => [ qw(r3) ],
  },
  inputs => [
    { input  => { r1 => 1, r2 => 2 },
      fields => { r1 => 1, r2 => 2, r3 => undef },
      valid  => 1,
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => 1,
    },
    { input  => { r1 => 1, r2 => 2, r3 => 3, r4 => 4 },
      fields => { r1 => 1, r2 => 2, r3 => 3 },
      valid  => 1,
    },
    { input  => { r1 => 'foo  ', r2 => '  bar', r3 => ' baz '},
      fields => { r1 => 'foo',   r2 => 'bar',   r3 => 'baz' },
      valid  => 1,
    },
    { input  => { r1 => 1, r3 => 3 },
      fields => { r1 => 1, r3 => 3, r2 => undef },
      valid  => 0,
      invalid => { r2 => 'required' },
    },
    { input  => { r1 => 1, r2 => '', r3 => 3 },
      fields => { r1 => 1, r3 => 3, r2 => '' },
      valid  => 0,
      invalid => { r2 => 'required' },
    },
  ],
},
{ profile => {
      required => 'r1',
      constraints => { r1 => 'email' },
  },
  inputs => [
    { input  => { r1 => 'foo@example.com' },
      fields => { r1 => 'foo@example.com' },
      valid  => 1,
    },
    { input  => { r1 => 'foo@example' },
      fields => { r1 => 'foo@example' },
      valid  => 0,
      invalid => { r1 => 'email' },
    },
    { input  => {  },
      fields => { r1 => undef },
      valid  => 0,
      invalid => { r1 => 'required' },
    },
  ],
},
{ profile => {
      required => 'r1',
      constraints => { r1 => 'numeric' },
  },
  inputs => [
    { input  => { r1 => 42 },
      fields => { r1 => 42 },
      valid  => 1,
    },
    { input  => {  },
      fields => { r1 => undef },
      valid  => 0,
      invalid => { r1 => 'required' },
    },
    { input  => { r1 => 'abc' },
      fields => { r1 => 'abc' },
      valid  => 0,
      invalid => { r1 => 'numeric' },
    },
  ],
},
{ profile => {
      optional    => 'r1',
      constraints => { r1 => 'numeric' },
  },
  inputs => [
    { input  => { r1 => 42 },
      fields => { r1 => 42 },
      valid  => 1,
    },
    { input  => {  },
      fields => { r1 => undef },
      valid  => 1,
    },
    { input  => { r1 => 'abc' },
      fields => { r1 => 'abc' },
      valid  => 0,
      invalid => { r1 => 'numeric' },
    },
  ],
},
);
require_ok('Act::Form');

for my $t (@tests) {
    my $f = Act::Form->new(%{$t->{profile}});
    ok($f);
    for my $i (@{$t->{inputs}}) {
        my $res = $f->validate($i->{input});
        ok($res == $i->{valid});
        is_deeply($f->fields, $i->{fields});
        if ($i->{invalid}) {
            is_deeply($f->invalid, $i->{invalid});
        }
        else {
            ok(!defined($i->{invalid}));
        }
    }
}

__END__
