use strict;
use Act::Util;
use Test::More qw(no_plan);

my @simple = qw(
    general_base_url
    general_cookie_name
    general_default_language
    general_dir_photos
    general_searchlimit
    database_name
    database_dsn
    database_user
    database_passwd
    database_pg_dump
    database_dump_file
    email_smtp_server
    email_sender_address
);
my @conf_simple = qw(
    uri
    general_timezone
    talks_submissions_open
    talks_submissions_notify_address
    talks_submissions_notify_language
    talks_show_schedule
    talks_start_date
    talks_end_date
    payment_open
    payment_type
);

BEGIN { use_ok('Act::Config') }
ok($Config, "configuration loaded");

## global config
_global_config($Config, 'global');

# test each conference configuration
isa_ok($Config->conferences, 'HASH', "general_conferences");
isa_ok($Config->uris, 'HASH', "uris");
for my $conf (keys %{$Config->conferences}) {
    my $cfg = Act::Config::get_config($conf);
    # global config may be overridden
    _global_config($cfg, $conf);
    # conference-specific
    ok(defined $cfg->$_, "$conf $_") for @conf_simple;
    isa_ok($cfg->talks_durations, 'HASH', "talks_durations");
    isa_ok($cfg->uris, 'HASH', "uris");
    like($_, qr/^\d+$/, "$conf talks_durations $_") for keys %{$cfg->talks_durations};
    isa_ok($cfg->name, 'HASH', 'name');
    ok($cfg->name->{$_}, "name $_")
        for keys %{$cfg->languages};
}
# uri <=> conf mapping
while (my ($uri, $conf) = each %{$Config->uris}) {
    like($uri, qr(^[^/]+$), "uri $uri");
    ok(exists $Config->conferences->{$conf}, "$uri points to existing conf $conf");
}

sub _global_config
{
    my ($cfg, $name) = @_;

    # simple fields
    ok($cfg->$_, "$name $_") for @simple;

    # languages
    isa_ok($cfg->languages, 'HASH', "$name general_languages");
    ok($cfg->languages->{$cfg->general_default_language}, "$name default_language is in languages");
    for my $lang (sort keys %{$cfg->languages}) {
        ok($Languages{$lang}, "$lang is in %Languages");
    }
}


__END__
