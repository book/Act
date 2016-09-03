#!/usr/bin/env perl
use strict;
use warnings;
use lib::abs 'lib';

use Act::Dispatcher;
use Plack::Builder;

builder {
    enable 'Session::Cookie',
        session_key => 'yapcrussia',
        expires     => 3600,
	secret      => 'abcddcba';
    enable "SimpleLogger", level => "warn";
    Act::Dispatcher->to_app;
};
