#!perl

use 5.010;
use strict;
use warnings;

use Data::Dump::OneLine qw(dump1);
use Data::Sah qw(gen_validator);
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
    my $name = $test->{name} // "$test->{input} vs ".dump1($test->{schema});
    if ($test->{valid}) {
        ok($v->($test->{input}), $name);
    } else {
        ok(!$v->($test->{input}), $name);
    }
}
done_testing();
