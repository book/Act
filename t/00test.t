use strict;
use Test;
BEGIN { plan tests => 1 }
eval { require Test::More };
if ($@) {
    warn "Test::More is required to run the test suite\n";
    ok(0);
}
ok(1);

__END__
