#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 88;
use Data::Schema;

for my $type (qw(all and)) {
    for (qw(of)) {
        my $sch = [$type => {$_ => [ [int=>{divisible_by=>2}], [int=>{divisible_by=>7}] ]}];

        valid(undef, $sch, "$_ undef");
        invalid(1, $sch, "$_ 1");
        invalid(4, $sch, "$_ 2");
        invalid(21, $sch, "$_ 3");
        valid(42, $sch, "$_ 4");
    }
}

test_deps('all', "1", {of=>["int", "str"]}, {of=>["int", "str", "hash"]});


