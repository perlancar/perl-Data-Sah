#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 2;
use Data::Schema;

is(Data::Schema::__stringf("%(1)D. %(2)c. %(0)s. %(0).", {0=>'s', 1=>{a=>1}, 2=>[1,'a',{}]}),
   q!{'a' => 1}. 1, a, {}. s. s.!, "__stringf (hashref)");

is(Data::Schema::__stringf("%(1)D. %(2)c. %(0)s. %(0).", ['s', {a=>1}, [1,'a',{}]]),
   q!{'a' => 1}. 1, a, {}. s. s.!, "__stringf (arrayref)");
