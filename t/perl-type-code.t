#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Data::Sah::Simple qw(gen_validator);
use Test::More 0.96;

# basic tests, not in spectest (yet)

my @tests = (
    {schema=>["code"], input=>"a", valid=>0},
    {schema=>["code"], input=>sub{}, valid=>1},
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
