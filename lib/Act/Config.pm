use utf8;
use strict;
package Act::Config;

use vars qw(@ISA @EXPORT $Config %Request %Languages);
@ISA    = qw(Exporter);
@EXPORT = qw($Config %Request %Languages );

use Act::Language;

use AppConfig qw(:expand :argcount);
use DateTime;
use DateTime::Format::HTTP;
use File::Spec::Functions qw(catfile);

# our configs
my ($GlobalConfig, %ConfConfigs, %Timestamps);

# language-specific constants
%Languages = (
    ar => { name               => 'العربية',
            fmt_datetime_full  => '%A %e %B %Y %H:%M',
            fmt_datetime_short => '%d-%m-%Y %H:%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d-%m-%Y',
            fmt_time           => '%H:%M',
            bidi               => 1,
          },
    be => { name               => 'Беларуская',
            fmt_datetime_full  => '%A, %e %{genitive_month} %Y г., %H:%M',
            fmt_datetime_short => '%d.%m.%y %H:%M',
            fmt_date_full      => '%A, %e %{genitive_month} %Y г.',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H:%M',
          },
    de => { name               => 'Deutsch',
            fmt_datetime_full  => '%A %B %e, %Y %H:%M',
            fmt_datetime_short => '%d/%m/%y %H:%M',
            fmt_date_full      => '%A %B %e, %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%H:%M',
          },
    en_GB => { name               => 'English',
            fmt_datetime_full  => '%A, %e %B %Y %H:%M',
            fmt_datetime_short => '%d/%m/%y %H:%M',
            fmt_date_full      => '%A, %e %B %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%H:%M',
          },
    en_US => { name               => 'English',
            fmt_datetime_full  => '%A, %B %e, %Y %I:%M %p',
            fmt_datetime_short => '%m/%d/%y %I:%M %p',
            fmt_date_full      => '%A, %B %e, %Y',
            fmt_date_short     => '%m/%d/%y',
            fmt_time           => '%I:%M %p',
          },
    es => { name               => 'Español',
            fmt_datetime_full  => '%e %B %Y %Hh%M',
            fmt_datetime_short => '%d/%m/%Y %Hh%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%Y',
            fmt_time           => '%Hh%M',
          },
    fr => { name               => 'français',
            fmt_datetime_full  => '%A %e %B %Y %Hh%M',
            fmt_datetime_short => '%d/%m/%y %Hh%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%Hh%M',
          },
    he => { name               => 'עברית',
            fmt_datetime_full  => '%A %e %B %Y %H:%M',
            fmt_datetime_short => '%d-%m-%y %H:%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d-%m-%y',
            fmt_time           => '%H:%M',
            bidi               => 1,
          },
    hr => { name               => 'Hrvatski',
            fmt_datetime_full  => '%A %B %e, %Y %H:%M',
            fmt_datetime_short => '%m/%d/%y %H:%M',
            fmt_date_full      => '%A %B %e, %Y',
            fmt_date_short     => '%m/%d/%y',
            fmt_time           => '%H:%M',
          },
    hu => { name               => 'Magyar',
            fmt_datetime_full  => '%Y %B %e, %A, %H:%M',
            fmt_datetime_short => '%Y %m %d %H:%M',
            fmt_date_full      => '%Y %B %e, %A',
            fmt_date_short     => '%Y %m %d',
            fmt_time           => '%H:%M',
          },
    it => { name               => 'Italiano',
            fmt_datetime_full  => '%A %e %B %Y, %H:%M',
            fmt_datetime_short => '%d/%m/%y %H:%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%H:%M',
          },
    ja => { name               => '日本語',
            fmt_datetime_full  => '%Y/%m/%d %H:%M',
            fmt_datetime_short => '%y/%m/%d %H:%M',
            fmt_date_full      => '%Y/%m/%d',
            fmt_date_short     => '%y/%m/%d',
            fmt_time           => '%H:%M',
          },
    nb => { name               => 'Norsk',
            fmt_datetime_full  => '%A %e %B %Y %H.%M',
            fmt_datetime_short => '%d.%m.%y %H.%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H.%M',
          },
    nl => { name               => 'Nederlands',
            fmt_datetime_full  => '%A %e %B %Y %H:%M',
            fmt_datetime_short => '%d-%m-%y %H:%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d-%m-%y',
            fmt_time           => '%H:%M',
          },
    pl => { name               => 'JĘzyk polski',
            fmt_datetime_full  => '%A, %e. %{genitive_month} %Y %H:%M',
            fmt_datetime_short => '%d.%m.%y %H:%M',
            fmt_date_full      => '%A, %e. %{genitive_month} %Y',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H:%M',
          },
    pt => { name               => 'Português',
            fmt_datetime_full  => '%A, %e de %B de %Y, %H:%M',
            fmt_datetime_short => '%y/%m/%d %H:%M',
            fmt_date_full      => '%A, %e de %B de %Y',
            fmt_date_short     => '%y/%m/%d',
            fmt_time           => '%H:%M',
          },
    ru => { name               => 'Русский',
            fmt_datetime_full  => '%A, %e %{genitive_month} %Y г., %H:%M',
            fmt_datetime_short => '%d.%m.%y %H:%M',
            fmt_date_full      => '%A, %e %{genitive_month} %Y г.',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H:%M',
          },
    sk => { name               => 'Slovenčina',
            fmt_datetime_full  => '%A, %e. %{genitive_month} %Y %H:%M',
            fmt_datetime_short => '%d.%m.%y %H:%M',
            fmt_date_full      => '%A, %e. %{genitive_month} %Y',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H:%M',
          },
    uk => { name               => 'Українська',
            fmt_datetime_full  => '%A, %e %{genitive_month} %Y р., %H:%M',
            fmt_datetime_short => '%d.%m.%y %H:%M',
            fmt_date_full      => '%A, %e %{genitive_month} %Y р.',
            fmt_date_short     => '%d.%m.%y',
            fmt_time           => '%H:%M',
          },
    zh => { name               => '中文',
            fmt_datetime_full  => '%Y/%m/%d %H:%M',
            fmt_datetime_short => '%y/%m/%d %H:%M',
            fmt_date_full      => '%Y/%m/%d',
            fmt_date_short     => '%y/%m/%d',
            fmt_time           => '%H:%M',
          },
);
# defaults
$Languages{en} = $Languages{'en_GB'};
$Languages{$_}{fmt_date_iso} = '%Y-%m-%d' for keys %Languages;

# image formats
our %Image_formats = (
    png     => '.png',
    jpeg    => '.jpg',
);

# optional variables
my @Optional = qw(
    talks_show_all talks_notify_accept talks_levels talks_languages
    talks_submissions_notify_address talks_submissions_notify_language
    database_debug general_dir_ttc
    flickr_apikey flickr_tags
    payment_prices payment_products payment_notify_address
    registration_open registration_max_attendees registration_gratis
    registration_gratis
    api_users
);

# salutations
our $Nb_salutations = 4;

# load configurations
load_configs() unless $^C;

sub load_configs
{
    my $home = $ENV{ACTHOME} // $ENV{ACT_HOME};
    die "ACT_HOME environment variable isn't set\n" unless $home;
    $GlobalConfig = _init_config($home);
    %ConfConfigs = ();
    %Timestamps  = ();

    # load global configuration
    _load_global_config($GlobalConfig, $home);

    # Sanity checking - disable for now, breaks testing
    #foreach (qw(general_dir_photos general_root)) {
    #    my $dir =$GlobalConfig->$_;
    #    die "Unable to find directory $dir for $_" unless -d $dir;
    #}

    # load conference-specific configuration files
    # their content may override global config settings
    my %uris;
    for my $conf (keys %{$GlobalConfig->conferences}) {
        # load conference configuration
        $ConfConfigs{$conf} = _init_config($home);
        _load_global_config($ConfConfigs{$conf}, $home);

        _load_config($ConfConfigs{$conf}, catfile($home, 'actdocs', $conf));

        # dockerize
        _load_config($ConfConfigs{$conf},
            catfile($GlobalConfig->general_dir_conferences, $conf, 'actdocs'));

        # conference languages
        my (%langs, %variants);
        for my $lang (split /\s+/, $ConfConfigs{$conf}->general_languages) {
            if ($lang =~ /^((\w+)_.*)$/) {    # $1 = en_US, $2 = en
                $lang = $2;
                $variants{$lang} = $1;
            }
            $langs{$lang} = 1;
        }
        $ConfConfigs{$conf}->set(languages => \%langs);
        $ConfConfigs{$conf}->set(language_variants => \%variants);

        # talk durations
        _make_hash($ConfConfigs{$conf}, talks_durations => $ConfConfigs{$conf}->talks_durations);

        # talk languages
        if ($ConfConfigs{$conf}->talks_languages) {
            $ConfConfigs{$conf}->set(
                talks_languages => { map { $_ => Act::Language::name($_) }
                                     split /\s+/, $ConfConfigs{$conf}->talks_languages
                                   });
        }
        else {
            $ConfConfigs{$conf}->set(
                talks_languages => {
                    map { $_ => Act::Language::name($_) }
                        split /\s+/, $ConfConfigs{$conf}->general_default_language
                }
            );
        }

        # room names
        my %rooms_names;
        _make_hash($ConfConfigs{$conf}, rooms_codes => $ConfConfigs{$conf}->rooms_rooms);
        for my $r (keys %{$ConfConfigs{$conf}->rooms_codes}) {
            for my $lang (keys %{$ConfConfigs{$conf}->languages}) {
                eval {
                    local $SIG{__WARN__} = sub {};
                    # new style: r1_name_en = TheName
                    $rooms_names{$r}{$lang} = $ConfConfigs{$conf}->get(join '_', 'rooms', $r, 'name', $lang);
                };
                # old style: r1 = TheName
                $rooms_names{$r}{$lang} ||= $ConfConfigs{$conf}->get("rooms_$r");
            }
        }
        $ConfConfigs{$conf}->set( rooms_names => \%rooms_names );

        # name of the conference in various languages
        $ConfConfigs{$conf}->set(name => { });
        for( keys %Languages ) {
            $ConfConfigs{$conf}->name->{$_} =
              # name in the language
              _get( $ConfConfigs{$conf}, "general_name_$_")
              # or in English
              || _get( $ConfConfigs{$conf}, "general_name_en")
              # or in the conference default language (if defined)
              || _get( $ConfConfigs{$conf}, "general_name_"
                 . $ConfConfigs{$conf}->get("general_default_language") )
              # or in the first available language for the conference
              || $ConfConfigs{$conf}->get("general_name_"
                 . ( $ConfConfigs{$conf}->get("general_languages"))[0] );
        }
        $ConfConfigs{$conf}->languages->{$_} = $Languages{$_}
            for keys %{$ConfConfigs{$conf}->languages};
        # conf <=> uri mapping
        my $uri = $conf;
        $uris{$uri} = $conf;
        $ConfConfigs{$conf}->set(uri => $uri);
        # api users
        _merge_api_users($ConfConfigs{$conf});
        # general_conferences isn't overridable
        $ConfConfigs{$conf}->set(conferences => $GlobalConfig->conferences);
    }
    # install uri to conf mapping
    $GlobalConfig->set(uris => \%uris);
    $ConfConfigs{$_}->set(uris => \%uris) for keys %{$GlobalConfig->conferences};

    # apply optional site policy
    _apply_site_policy();

    # default current config (for non-web stuff that doesn't call get_config)
    $Config = $GlobalConfig;
}
# reload configuration if one of the ini files has changed
sub reload_configs
{
    while (my ($file, $timestamp) = each %Timestamps) {
        my $mtime = (stat($file))[9];
        if (!defined($mtime) or $mtime > $timestamp) {
            load_configs();
            last;
        }
    }
}
# get configuration for current request
sub get_config
{
    my $conf = shift;
    if ($conf && $ConfConfigs{$conf}) {
        ## see if conference is closed
        # closed by configuraiton
        my $closed = !$ConfConfigs{$conf}->registration_open;
        # past conference's closing date
        unless ($closed) {
            my $enddate = DateTime::Format::HTTP->parse_datetime($ConfConfigs{$conf}->talks_end_date);
            $enddate->set_time_zone($ConfConfigs{$conf}->general_timezone);
            $closed = ( DateTime->now() > $enddate );
        }
        # max attendees reached
        if (!$closed && $ConfConfigs{$conf}->registration_max_attendees && $Request{dbh}) {
            my $sql = 'SELECT COUNT(*) FROM participations p WHERE p.conf_id=?';
            my @values = ($conf);
            if ($ConfConfigs{$conf}->payment_type ne 'NONE') {
                $sql .= <<EOF;
 AND (
     EXISTS(SELECT 1 FROM talks t WHERE t.user_id=p.user_id AND t.conf_id=? AND t.accepted IS TRUE)
  OR EXISTS(SELECT 1 FROM rights r WHERE r.user_id=p.user_id AND r.conf_id=? AND r.right_id IN (?,?,?))
  OR EXISTS(SELECT 1 FROM orders o, order_items i WHERE o.user_id=p.user_id AND o.conf_id=? AND o.status=?
                                                    AND o.order_id = i.order_id AND i.registration)
)
EOF
                push @values, $conf,
                              $conf, 'admin_users', 'admin_talks', 'staff',
                              $conf, 'paid';
            }
            my $sth = $Request{dbh}->prepare_cached($sql);
            $sth->execute(@values);
            my ($count) = $sth->fetchrow_array();
            $sth->finish();

            $closed = ( $count >= $ConfConfigs{$conf}->registration_max_attendees );
        }
        $ConfConfigs{$conf}->set(closed => $closed);

        return $ConfConfigs{$conf}
    }
    return $GlobalConfig;
}
# finalize config once $Request{language} is set
sub finalize_config
{
    my ($cfg, $language) = @_;

    # room names in current language
    my $allnames = $cfg->rooms_names;
    my %names;
    for my $r (keys %$allnames) {
        $names{$r} =  $allnames->{$r}{$language}
                   || $allnames->{$r}{$cfg->general_default_language}
                   || $allnames->{$r}{en};
    }
    $cfg->set(rooms => \%names);

    # talk level names in current language
    $cfg->set(talks_levels_names => 
            [ map $cfg->get("levels_level$_\_name_$language"),
                  1 .. $cfg->talks_levels ]);

}
# get optional variable
sub get_optional
{
    my ($varname) = @_;
    my $result;
    my $errhandler = $Config->{STATE}->_ehandler();
    $Config->{STATE}->_ehandler( sub { } );
    $result = $Config->get($varname);
    $Config->{STATE}->_ehandler($errhandler);
    return $result;
}

sub _init_config
{
    my $home = shift;
    my $cfg = AppConfig->new(
         {
            CREATE => 1,
            GLOBAL => {
                   DEFAULT  => "<undef>",
                   ARGCOUNT => ARGCOUNT_ONE,
                   EXPAND   => EXPAND_VAR,
               }
         }
    );
    $cfg->set(home => $home);
    # optional settings
    $cfg->set($_ => undef) for @Optional;
    return $cfg;
}
sub _get
{
    my ($cfg, $name) = @_;
    return $cfg->_exists($name) ? $cfg->get($name) : '';
}
sub _load_config
{
    my ($cfg, $dir) = @_;
    for my $file (qw< act local >) {
        my $path = catfile($dir, 'conf', "$file.ini");
        if (-e $path) {
            open my $fh, '<:encoding(UTF-8)', $path
                or die "can't open $path: $!\n";
            $cfg->file($fh);
            $Timestamps{$path} = (stat $fh)[9];
            close $fh;
        }
    }
}

sub _load_global_config
{
    my ($cfg, $dir) = @_;
    _load_config($cfg, $dir);

    _make_hash  ($cfg, conferences => $cfg->general_conferences);
    $cfg->set($_ => {}) for qw(api_keys);
    _merge_api_users($cfg);
}

sub _merge_api_users
{
    my $cfg = shift;
    if ($cfg->api_users) {
        my $api_keys  = $cfg->api_keys;
        for my $user (split /\s+/, $cfg->api_users) {
            my $key = $cfg->get("api_user_${user}_key");
            $api_keys->{ $key } = $user;
        }
        $cfg->set(api_keys => $api_keys);
    }
}
sub _make_hash
{
    my ($cfg, %h) = @_;
    while (my ($key, $value) = each %h) {
        $cfg->set($key => { map { $_ => 1 } split /\s+/, $value });
    }
}
sub _apply_site_policy
{
    # read optional site policy configuration file
    my $file = catfile($GlobalConfig->home, 'conf', 'site.ini');
    -e $file or return;
    my $cfg = AppConfig->new({ CREATE => 1,
                               GLOBAL => { ARGCOUNT => ARGCOUNT_ONE }
                            });
    $cfg->file($file);

    # apply policy
    my %vars = $cfg->varlist('^');
    for my $var (keys %vars) {
        my ($conf, $varname) = split '_', $var, 2;
        if (exists $ConfConfigs{$conf}) {
            my $value = $cfg->get($var);
            $ConfConfigs{$conf}->set($varname => $value);
        }
    }
}

1;
__END__

=head1 NAME

Act::Config - read configuration files

=head1 SYNOPSIS

    use Act::Config;
    Act::Config::get_config($conference);

=cut
