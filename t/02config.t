use strict;
use Test::More tests => 11;

BEGIN { use_ok('Act::Config') }
ok($Config, "config chargée");

isa_ok($Config->conferences, 'HASH', "general_conferences");
isa_ok($Config->languages,   'HASH', "general_languages");
ok($Config->general_default_language, "general_default_language");
ok($Config->languages->{$Config->general_default_language}, "default_language is in languages");

for my $key (qw(dsn user passwd)) {
  my $pref = "database_$key";
  ok($Config->$pref, $pref);
}

ok($Config->email_smtp_server, 'smtp_server');
ok($Config->general_dir_photos, 'dir_photos');

__END__
