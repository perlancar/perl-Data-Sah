#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";

require "testlib.pl";
use Test::More 0.98;

run_spectest('human');
done_testing();
