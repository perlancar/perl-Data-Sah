#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 1;
use Data::Schema;

my $d = {i=>1, s=>"str"}; $d->{h} = $d;
my $s = [hash=>{set=>1, keys=>{i=>"int", s=>"str"}}]; $s->[1]{keys}{h} = $s;

valid($d, $s, "hash:keys");
