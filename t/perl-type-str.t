#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah qw(gen_validator);
use Test::More 0.96;

my @tests = (
    # test that match in perl accepts regexp object too
    {schema=>["str*", match=>qr!/!], input=>"a" , valid=>0},
    {schema=>["str*", match=>qr!/!], input=>"a/", valid=>1},
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
