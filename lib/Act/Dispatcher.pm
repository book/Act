use strict;
package Act::Dispatcher;

use Act::Config;
use Act::Handler::Static;
use Act::Util;

use Encode qw(decode_utf8);
use List::Util qw(first);
use Module::Pluggable::Object;
use Plack::App::Cascade;
use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::Debug;
use Plack::Request;

# main dispatch table
my %public_handlers = (
    api             => 'Act::Handler::WebAPI',
    atom            => 'Act::Handler::News::Atom',
    changepwd       => 'Act::Handler::User::ChangePassword',
    event           => 'Act::Handler::Event::Show',
    events          => 'Act::Handler::Event::List',
    faces           => 'Act::Handler::User::Faces',
    favtalks        => 'Act::Handler::Talk::Favorites',
    login           => 'Act::Handler::Login',
    news            => 'Act::Handler::News::List',
    openid          => 'Act::Handler::OpenID',
    proceedings     => 'Act::Handler::Talk::Proceedings',
    slides          => 'Act::Handler::Talk::Slides',
    register        => 'Act::Handler::User::Register',
    schedule        => 'Act::Handler::Talk::Schedule',
    search          => 'Act::Handler::User::Search',
    stats           => 'Act::Handler::User::Stats',
    talk            => 'Act::Handler::Talk::Show',
    talks           => 'Act::Handler::Talk::List',
    'timetable.ics' => 'Act::Handler::Talk::ExportIcal',
    user            => 'Act::Handler::User::Show',
    wiki            => 'Act::Handler::Wiki',
);

my %private_handlers = (
    change          => 'Act::Handler::User::Change',
    create          => 'Act::Handler::User::Create',
    csv             => 'Act::Handler::CSV',
    confirm_attend  => 'Act::Handler::User::ConfirmAttendance',
    editevent       => 'Act::Handler::Event::Edit',
    edittalk        => 'Act::Handler::Talk::Edit',
    export          => 'Act::Handler::User::Export',
    export_talks    => 'Act::Handler::Talk::ExportCSV',
    ical_import     => 'Act::Handler::Talk::Import',
    invoice         => 'Act::Handler::Payment::Invoice',
    logout          => 'Act::Handler::Logout',
    main            => 'Act::Handler::User::Main',
    myschedule      => 'Act::Handler::Talk::MySchedule',
    'myschedule.ics'=> 'Act::Handler::Talk::ExportMyIcal',
    newevent        => 'Act::Handler::Event::Edit',
    newsadmin       => 'Act::Handler::News::Admin',
    newsedit        => 'Act::Handler::News::Edit',
    newtalk         => 'Act::Handler::Talk::Edit',
    orders          => 'Act::Handler::User::Orders',
    openid_trust    => 'Act::Handler::OpenID::Trust',
    payment         => 'Act::Handler::Payment::Edit',
    payments        => 'Act::Handler::Payment::List',
    photo           => 'Act::Handler::User::Photo',
    punregister     => 'Act::Handler::Payment::Unregister',
    purchase        => 'Act::Handler::User::Purchase',
    rights          => 'Act::Handler::User::Rights',
    trackedit       => 'Act::Handler::Track::Edit',
    tracks          => 'Act::Handler::Track::List',
    updatemytalks   => 'Act::Handler::User::UpdateMyTalks',
    updatemytalks_a => 'Act::Handler::User::UpdateMyTalks::ajax_handler',
    unregister      => 'Act::Handler::User::Unregister',
    wikiedit        => 'Act::Handler::WikiEdit',
);

sub to_app {
    Act::Config::reload_configs();
    my $conference_app = conference_app();
    my $app            = builder {
        enable 'Debug', panels => [split(/\s+/, $ENV{ACT_DEBUG})]
            if $ENV{ACT_DEBUG};

        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);

                # Make sure there is no trailing slash in base_url
                my $base_url = $req->base->as_string;
                $base_url =~ s{/$}{};
                $env->{'act.base_url'} = $base_url;
                $env->{'act.dbh'}      = Act::Util::db_connect();
                $app->($env);
            };
        };
        my %confr = %{ $Config->uris },
            map { $_ => $_ } %{ $Config->conferences };
        for my $uri (keys %confr) {
            my $conference = $confr{$uri};
            mount "/$uri/" => sub {
                my $env = shift;
                $env->{'act.conference'} = $conference;
                $env->{'act.config'} = Act::Config::get_config($conference);
                $conference_app->($env);
            };
        }
        mount "/" => sub {
            [404, [], []];
        };
    };
    return $app;
}

sub conference_app {
    my $static_app = builder {
        enable '+Act::Middleware::Auth';
        Act::Handler::Static->new->to_app;
    };
    builder {
        enable '+Act::Middleware::Language';
        enable sub {
            my $app = shift;
            sub {
                for ( $_[0]->{'PATH_INFO'} ) {
                    if ( s{^/?$}{index.html} || /\.html$/ ) {
                        return $static_app->(@_);
                    }
                    else {
                        return $app->(@_);
                    }
                }
            };
        };
        Plack::App::Cascade->new( catch => [99], apps => [
            builder {
                # XXX ugly, but functional for now
                enable sub {
                    my ( $app ) = @_;

                    return sub {
                        my ( $env ) = @_;

                        my $res = $app->($env);
                        $res->[0] = 99 if $res->[0] == 404;
                        return $res;
                    };
                };
                Plack::App::File->new(root => $Config->general_root)->to_app;
            },
            builder {
                enable '+Act::Middleware::Auth';
                for my $uri ( keys %public_handlers ) {
                    mount "/$uri" => _handler_app($public_handlers{$uri});
                }
                mount '/' => sub { [99, [], []] };
            },
            builder {
                enable '+Act::Middleware::Auth', private => 1;
                for my $uri ( keys %private_handlers ) {
                    mount "/$uri" => _handler_app($private_handlers{$uri});
                }
                mount '/' => sub { [404, [], []] };
            }
        ] );
    };
}


{
    my @HANDLERS;
    my $search_path = 'Act::Handler';
    sub _load_handler_plugins {
        if (!@HANDLERS) {
            my $finder = Module::Pluggable::Object->new(
                search_path => $search_path,
                require     => 1,
            );
            @HANDLERS = $finder->plugins;
        }
    }

    sub _get_handler_plugin {
        my ($handler) = @_;

        my $subhandler;
        if ($handler =~ s/::(\w+_handler)$//) {
            $subhandler = $1;
        }

        _load_handler_plugins;
        if (my $plugin = first { $handler eq $_ } @HANDLERS) {
            return $handler->new(subhandler => $subhandler) if defined $subhandler;
            return $handler->new();
        }
        die sprintf("Unable to load '%s', not found in search path: '%s'!\n",
            $handler, $search_path);
    }
}


sub _handler_app {
    my ($handler) = @_;
    return _get_handler_plugin($handler)->to_app;
}

1;
__END__

=head1 NAME

Act::Dispatcher - Dispatch web request

=head1 SYNOPSIS

No user-serviceable parts. Warranty void if open.

=cut
