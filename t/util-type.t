#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah::Util::Type qw(coerce_date);
use DateTime;
use Test::More 0.98;

subtest coerce_date => sub {
    ok(!defined(coerce_date(undef)));
    ok(!defined(coerce_date("x")));
    ok(!defined(coerce_date(100_000)));
    ok(!defined(coerce_date(3_000_000_000)));
    ok(!defined(coerce_date("2014-04-31")));

    ok( defined(coerce_date("2014-04-25")));
    ok( defined(coerce_date(100_000_000)));
    ok( defined(coerce_date(DateTime->now)));
};

done_testing;
