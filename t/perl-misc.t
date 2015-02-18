#!perl

use 5.010;
use strict;
use warnings;

use DateTime;
use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.96;

# check double popping of _sahv_dpath, fixed in 0.42+

my @tests = (
    {
        schema => ["array", {of=>["hash", keys=>{a=>[array=>of=>"any"]}]}],
        input  => [{a=>[]}, {a=>[]}],
        valid  => 1,
    },
);
test_sah_cases(\@tests, {gen_validator_opts=>{return_type=>"str"}});

done_testing();