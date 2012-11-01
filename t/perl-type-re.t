#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah qw(gen_validator);
use Test::More 0.96;

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["re*"], input=>""  , valid=>1},
    {schema=>["re*"], input=>"x" , valid=>1},
    {schema=>["re*"], input=>qr//, valid=>1},
    {schema=>["re*"], input=>"(" , valid=>0},
    {schema=>["re*"], input=>[]  , valid=>0},
    {schema=>["re*"], input=>{}  , valid=>0},
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
