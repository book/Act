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
    email_sendmail
    email_sender_address
    wiki_dbname
    wiki_dbuser
    wiki_dbpass
);
my @conf_simple = qw(
    uri
    closed
    general_full_uri
    general_default_language
    general_default_country
    general_timezone
    talks_submissions_open
    talks_show_schedule
    talks_start_date
    talks_end_date
    rooms_rooms
    payment_type
);

BEGIN { use_ok('Act::Language') }
BEGIN { use_ok('Act::Config') }
ok($Config, "configuration loaded");

## Act::Config globals
for my $lang (sort keys %Languages) {
    my $loc = DateTime::Locale->load($lang);
    ok($loc, "locale $lang");
}

## global config
_test_config($Config, 'global');

# optional compiled templates
if ($Config->general_dir_ttc) {
    ok(-d $Config->general_dir_ttc, "compiled templates directory exists");
}

# test each conference configuration
isa_ok($Config->conferences, 'HASH', "general_conferences");
isa_ok($Config->uris, 'HASH', "uris");
my %payment_types;
for my $conf (sort keys %{$Config->conferences}) {
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
    for my $lang (sort values %{$cfg->language_variants}) {
        if ($lang =~ /^((\w+)_.*)$/) {    # $1 = en_US, $2 = en
            my ($variant, $lang) = ($1, $2);
            if (exists $Languages{$variant}) {
                ok($Languages{$variant}, "$conf $variant is in %Languages");
            }
            else {
                ok($Languages{$lang}, "$conf $variant => $lang is in %Languages");
            }
        }
        else {
            ok($Languages{$lang}, "$conf $lang is in %Languages");
        }
    }
    # names
    isa_ok($cfg->name, 'HASH', "$conf name");
    ok($cfg->name->{$_}, "$conf name $_")
        for keys %{$cfg->languages};

    # talk levels
    if ($cfg->talks_levels) {
        for my $i (1 .. $cfg->talks_levels) {
            ok($cfg->get("levels_level$i\_name_$_"), "$conf talks level $i in $_")
                for keys %{$cfg->languages};
        }
    }
    # talk languages
    if ($cfg->talks_languages) {
        ok(Act::Language::name($_), "$conf talks languages $_")
            for keys %{$cfg->talks_languages};
    }
    # rooms
    isa_ok($cfg->rooms_names, 'HASH', "$conf rooms_names");
    for my $r (keys %{ $cfg->rooms_names }) {
        ok($cfg->rooms_names->{$r}{$_}, "$conf room $r name $_")
                for keys %{$cfg->languages};
    }    
    # payment
    if ($cfg->payment_type eq 'NONE') {
        ok(1, "$conf payment_type NONE");
    }
    else {
        ok(defined $cfg->$_, "$conf $_")
            for qw(payment_open payment_currency);
        ok($cfg->$_, "$conf $_")
            for qw(payment_currency);
        ok($cfg->payment_prices || $cfg->payment_products, "$conf payment prices or products");
        if ($cfg->payment_prices) {     # old style prices
            for my $i (1 .. $cfg->payment_prices) {
                my $key = "price$i";
                ok($cfg->get($key . '_amount'), "$conf $key amount");
                ok($cfg->get($key . "_name_$_"), "$conf $key name_$_")
                    for keys %{$cfg->languages};
            }
        }
        if ($cfg->payment_products) {   # new style products
            ok($cfg->payment_products, "$conf payment_products");
            for my $product (split /\s+/, $cfg->payment_products) {
                my $key = "product_$product";
                ok($cfg->get($key . "_name_$_"), "$conf $key name_$_")
                    for keys %{$cfg->languages};
                my $prices = $cfg->get($key . "_prices");
                ok($prices, "$conf $key prices");
                for my $i (1..$prices) {
                    my $pkey = $key . "_price$i";
                    ok(defined $cfg->get($pkey . '_amount'), "$conf $pkey amount");
                    if ($prices > 1) {
                        ok($cfg->get($pkey . "_name_$_"), "$conf $pkey name_$_")
                            for keys %{$cfg->languages};
                    }
                }
            }
        }
    }
    # api keys
    isa_ok($cfg->api_keys, 'HASH', "$conf api_keys");

    # remember payment type
    $payment_types{$cfg->payment_type} = 1;
}
# uri <=> conf mapping
while (my ($uri, $conf) = each %{$Config->uris}) {
    is($uri, $conf, "$uri points to existing conf $conf");
}
# payment types
for my $type (sort keys %payment_types) {
    next if $type eq 'NONE';
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
