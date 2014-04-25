#!perl

# minimal and temporary tests, pending real date spectest from Sah

use 5.010;
use strict;
use warnings;

use Data::Sah::JS qw(gen_validator);
use DateTime;
use Test::More 0.96;

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["date"], input=>"2014-01-25", valid=>1},
    # {schema=>["date"], input=>"2014-02-30", valid=>0}, # node.js cheats by not really validating diligently
    {schema=>["date"], input=>"2014-02-32", valid=>0}, # node.js cheats by not really validating diligently
    {schema=>["date"], input=>"x", valid=>0},
    {schema=>["date"], input=>100_000_000, valid=>1},
    {schema=>["date"], input=>100_000, valid=>0},

    {schema=>["date", min=>"2014-01-01"], input=>"2013-12-12", valid=>0},
    {schema=>["date", min=>"2014-01-02"], input=>"2014-01-02", valid=>1},
    {schema=>["date", min=>"2014-01-02"], input=>"2014-02-01", valid=>1},
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
