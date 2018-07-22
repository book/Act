#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable 'Session::Cookie',
        session_key => 'act',
        expires     => 3600, # 1 hour
        secret      => 'actdemo'
        ;
    enable "SimpleLogger", level => "info";
    Act::Dispatcher->to_app;
};
