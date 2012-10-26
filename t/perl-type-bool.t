#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Data::Sah::Simple qw(gen_validator);
use Test::More 0.96;

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["bool*", is_true=>0], input=>"", valid=>1},
    {schema=>["bool*", is_true=>1], input=>"a", valid=>1},
    {schema=>["bool*", is_true=>1], input=>0.1, valid=>1},
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
