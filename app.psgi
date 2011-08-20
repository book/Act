#!/usr/bin/env perl

use strict;
use warnings;

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable 'Session::Cookie';
    Act::Dispatcher->to_app;
};
