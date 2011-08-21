#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable 'Session::Cookie';
    enable "SimpleLogger", level => "warn";
    enable 'SimpleContentFilter', filter => sub {
        if ( utf8::is_utf8($_) ) {
            utf8::encode($_);
        }
    };
    Act::Dispatcher->to_app;
};
