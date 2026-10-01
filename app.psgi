#!/usr/bin/env perl
use strict;
use warnings;
use lib::abs 'lib';

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable "SimpleLogger", level => "warn";
    Act::Dispatcher->to_app;
};
