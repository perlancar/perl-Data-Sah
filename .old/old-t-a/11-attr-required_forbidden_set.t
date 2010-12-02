#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 82-24;
use Test::Exception;
use Data::Schema;

my $ds = Data::Schema->new;

# required
valid  (1,     [int=>{required=>1}], 'required 1');
valid  (0,     [int=>{required=>1}], 'required 2');
valid  ('',    [str=>{required=>1}], 'required 2 str');
invalid(undef, [int=>{required=>1}], 'required 3');
valid  (undef, [int=>{required=>0}], 'required 4');
# alias for required: set=>1
valid  (1,     [int=>{set=>1}], 'set 1');
valid  (0,     [int=>{set=>1}], 'set 2');
valid  ('',    [str=>{set=>1}], 'set 2 str');
invalid(undef, [int=>{set=>1}], 'set 3');
valid  (undef, [int=>{set=>undef}], 'set 4');

# common attribute: forbidden
invalid(1,     [int=>{forbidden=>1}], 'forbidden 1');
invalid(0,     [int=>{forbidden=>1}], 'forbidden 2');
invalid('',    [str=>{forbidden=>1}], 'forbidden 2 str');
valid  (undef, [int=>{forbidden=>1}], 'forbidden 3');
valid  (undef, [int=>{forbidden=>0}], 'forbidden 4');
# alias for forbidden: set=>0
invalid(1,     [int=>{set=>0}], 'set 5');
invalid(0,     [int=>{set=>0}], 'set 6');
invalid('',    [str=>{set=>0}], 'set 6 str');
valid  (undef, [int=>{set=>0}], 'set 7');
valid  (undef, [int=>{set=>undef}], 'set 8');

# attribute conflict: required/forbidden & set
#dies_ok(sub {$ds->validate(0,     [int=>{required=>1, forbidden=>1}])}, 'conflict required+forbidden 1a');
#dies_ok(sub {$ds->validate(undef, [int=>{required=>1, forbidden=>1}])}, 'conflict required+forbidden 1b');
#valid  (0,     [int=>{required=>1, forbidden=>0}], 'conflict required+forbidden 2a');
#invalid(undef, [int=>{required=>1, forbidden=>0}], 'conflict required+forbidden 2b');
#invalid(0,     [int=>{required=>0, forbidden=>1}], 'conflict required+forbidden 3a');
#valid  (undef, [int=>{required=>0, forbidden=>1}], 'conflict required+forbidden 3b');
#valid  (0,     [int=>{required=>0, forbidden=>0}], 'conflict required+forbidden 4a');
#valid  (undef, [int=>{required=>0, forbidden=>0}], 'conflict required+forbidden 4b');
# conflict alias set=1 for required
#dies_ok(sub{$ds->validate(0,     [int=>{set=>1, forbidden=>1}])}, 'conflict set+forbidden 1a');
#dies_ok(sub{$ds->validate(undef, [int=>{set=>1, forbidden=>1}])}, 'conflict set+forbidden 1b');
#valid  (0,     [int=>{set=>1, forbidden=>0}], 'conflict set+forbidden 2a');
#invalid(undef, [int=>{set=>1, forbidden=>0}], 'conflict set+forbidden 2b');
#invalid(0,     [int=>{set=>undef, forbidden=>1}], 'conflict set+forbidden 3a');
#valid  (undef, [int=>{set=>undef, forbidden=>1}], 'conflict set+forbidden 3b');
#valid  (0,     [int=>{set=>undef, forbidden=>0}], 'conflict set+forbidden 4a');
#valid  (undef, [int=>{set=>undef, forbidden=>0}], 'conflict set+forbidden 4b');
# conflict alias set=0 for forbidden
#dies_ok(sub{$ds->validate(0,     [int=>{required=>1, set=>0}])}, 'conflict required+set 1a');
#dies_ok(sub{$ds->validate(undef, [int=>{required=>1, set=>0}])}, 'conflict required+set 1b');
#valid  (0,     [int=>{required=>1, set=>undef}], 'conflict required+set 2a');
#invalid(undef, [int=>{required=>1, set=>undef}], 'conflict required+set 2b');
#invalid(0,     [int=>{required=>0, set=>0}], 'conflict required+set 3a');
#valid  (undef, [int=>{required=>0, set=>0}], 'conflict required+set 3b');
#valid  (0,     [int=>{required=>0, set=>undef}], 'conflict required+set 4a');
#valid  (undef, [int=>{required=>0, set=>undef}], 'conflict required+set 4b');


