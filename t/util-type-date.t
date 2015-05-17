#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

plan skip_all => "DateTime not available" unless eval { require DateTime; 1 };

use Data::Sah::Util::Type::Date qw(coerce_date);

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
