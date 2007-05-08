use strict;
use Act::Util;
use DateTime::Locale;
use Test::More qw(no_plan);

my @simple = qw(
    general_cookie_name
    general_dir_photos
    general_max_imgsize
    general_searchlimit
    database_name
    database_dsn
    database_user
    database_passwd
    database_pg_dump
    database_dump_file
    email_smtp_server
    email_sender_address
    wiki_dbname
    wiki_dbuser
    wiki_dbpass
);
my @conf_simple = qw(
    uri
    general_full_uri
    general_default_language
    general_default_country
    general_timezone
    talks_submissions_open
    talks_submissions_notify_address
    talks_submissions_notify_language
    talks_show_schedule
    talks_start_date
    talks_end_date
    payment_open
    payment_type
    payment_prices
);

BEGIN { use_ok('Act::Config') }
ok($Config, "configuration loaded");

## Act::Config globals
for my $lang (sort keys %Languages) {
    my $loc = DateTime::Locale->load($lang);
    ok($loc, "locale $lang");
}

## global config
_test_config($Config, 'global');

# test each conference configuration
isa_ok($Config->conferences, 'HASH', "general_conferences");
isa_ok($Config->uris, 'HASH', "uris");
my %payment_types;
for my $conf (keys %{$Config->conferences}) {
    my $cfg = Act::Config::get_config($conf);
    # global config may be overridden
    _test_config($cfg, $conf);
    # conference-specific
    ok(defined $cfg->$_, "$conf $_") for @conf_simple;
    isa_ok($cfg->talks_durations, 'HASH', "$conf talks_durations");
    isa_ok($cfg->uris, 'HASH', "$conf uris");
    like($_, qr/^\d+$/, "$conf talks_durations $_") for keys %{$cfg->talks_durations};
    # languages
    isa_ok($cfg->languages, 'HASH', "$conf general_languages");
    ok($cfg->languages->{$cfg->general_default_language}, "$conf default_language is in languages");
    for my $lang (sort keys %{$cfg->languages}) {
        ok($Languages{$lang}, "$conf $lang is in %Languages");
    }
    # names
    isa_ok($cfg->name, 'HASH', "$conf name");
    ok($cfg->name->{$_}, "$conf name $_")
        for keys %{$cfg->languages};
    # prices
    my $oldstyle;
    my $errhandler = $cfg->{STATE}->_ehandler();
    $cfg->{STATE}->_ehandler( sub { $oldstyle = 1 } );
    $cfg->payment_currency;
    $cfg->{STATE}->_ehandler($errhandler);

    ok(!$oldstyle, "$conf open payment is new style")
        if $cfg->payment_open;
    for my $i (1 .. $cfg->payment_prices) {
        my $key = "price$i";
        ok($cfg->get($key . '_amount'), "$conf $key amount");
        if ($oldstyle) {
            ok($cfg->get($key . "_$_"), "$conf $key $_")
                for qw(type currency);
        }
        else {
            ok($cfg->get($key . "_name_$_"), "$conf $key name_$_")
                for keys %{$cfg->languages};
        }
    }
    # remember payment type
    $payment_types{$cfg->payment_type} = 1;
}
# uri <=> conf mapping
while (my ($uri, $conf) = each %{$Config->uris}) {
    is($uri, $conf, "$uri points to existing conf $conf");
}
# payment types
for my $type (sort keys %payment_types) {
    my $prefix = 'payment_type_' . $type . '_';
    my $plugin_type = $Config->get($prefix . 'plugin');
    ok($plugin_type, "payment_type_$type: plugin type = $plugin_type");
    ok($Config->get($prefix . 'notify_bcc'), "payment_type_$type notify_bcc");
}

sub _test_config
{
    my ($cfg, $name) = @_;

    # simple fields
    ok($cfg->$_, "$name $_") for @simple;
}


__END__
