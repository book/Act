NOOP = /bin/sh -c true

test ::
	@perl -e 'use Test::Harness; runtests @ARGV;' t/*.t
