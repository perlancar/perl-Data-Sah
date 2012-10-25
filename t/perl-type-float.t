#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Data::Sah::Simple qw(gen_validator);
use Test::More 0.96;

my @tests = (
    {schema=>[float => is_nan => 1], input=>1, valid=>0},
    {schema=>[float => is_nan => 1], input=>"Inf", valid=>0},
    {schema=>[float => is_nan => 1], input=>"NaN", valid=>1},

    {schema=>[float => is_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_inf => 1], input=>"-Inf", valid=>1},
    {schema=>[float => is_inf => 1], input=>"Inf", valid=>1},

    {schema=>[float => is_pos_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"-Inf", valid=>0},
    {schema=>[float => is_pos_inf => 1], input=>"Inf", valid=>1},

    {schema=>[float => is_neg_inf => 1], input=>1, valid=>0},
    {schema=>[float => is_neg_inf => 1], input=>"NaN", valid=>0},
    {schema=>[float => is_neg_inf => 1], input=>"-Inf", valid=>1},
    {schema=>[float => is_neg_inf => 1], input=>"Inf", valid=>0},
);

for my $test (@tests) {
    my $v = gen_validator($test->{schema});
    if ($test->{valid}) {
        ok($v->($test->{input}), $test->{name});
    } else {
        ok(!$v->($test->{input}), $test->{name});
    }
}
done_testing();
