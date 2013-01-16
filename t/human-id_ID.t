#!perl

# some checks for human compilation (lang=en_US). currently only for sanity, not
# thorough at all.

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";

require "testlib.pl";
use Test::More 0.96;

my @tests = (
    {schema=>"int",
     result=>"bilangan bulat"},

    # array
    # -- test ordinate()
    {schema=>[array => elems => ["int"]],
     result=>"larik, elemen ke-1 harus: bilangan bulat"},
);

for my $test (@tests) {
    test_human(lang=>"id_ID", %$test);
}
done_testing;
