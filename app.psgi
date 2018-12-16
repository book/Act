#!/usr/bin/env perl
use strict;
use warnings;
use lib::abs 'lib';

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable 'Session',
        session_key => 'act_session',
        expires     => 3600 * 24 * 30, # 30 days
        secret      => 'abcddcba';
    enable "SimpleLogger", level => "warn";
    Act::Dispatcher->to_app;
};
