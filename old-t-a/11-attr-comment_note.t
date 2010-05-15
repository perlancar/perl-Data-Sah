#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 64;
use Data::Schema;

# these attribute have no effect whatsoever on result

for my $a (qw(comment note)) {
    for (undef, "", 0, 1, -1, "int", [], {}) {
	my $r = defined($_) ? (ref($_) ? ref($_) : ($_ eq '' ? "emptystr" : $_)) : "undef";
	valid  (1, [int=>{min=>1, "$a"=>1}], "$a $r valid");
	invalid(0, [int=>{min=>1, "$a"=>1}], "$a $r invalid");
    }
}


