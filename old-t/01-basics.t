#!perl -T

use lib './t'; require 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 66;
use Test::Exception;
use Data::Schema;

my $ds;
my $res;

$ds = new Data::Schema;

$res = ds_validate(1, 'int');
ok($res && $res->{success}, 'procedural interface');

# first form
dies_ok(sub { $res = $ds->validate(1) }, 'schema error: missing');
dies_ok(sub { $ds->validate(1, 'foo') }, 'schema error: unknown type [1f]');

# second form
invalid(2, [int=>{divisible_by=>2}=>{divisible_by=>3}], 'multiple attrhash 1.1');
invalid(3, [int=>{divisible_by=>2}=>{divisible_by=>3}], 'multiple attrhash 1.2');
valid  (6, [int=>{divisible_by=>2}=>{divisible_by=>3}], 'multiple attrhash 1.3');
dies_ok(sub { $ds->validate(1, ['foo']) }, 'schema error: unknown type (2f)');
dies_ok(sub { $ds->validate(1, [int=>{foo=>1}]) }, 'schema error: unknown attr (2f)');
dies_ok(sub { $ds->validate(1, [int=>{deps=>1}]) }, 'schema error: incorrect attr arg (2f)'); # XXX should test on every known attr

# third form
valid  ( 1, {type=>'int'}, 'third form 0.1');
invalid([], {type=>'int'}, 'third form 0.2');
valid  (10, {type=>'int', attrs=>{min=>10}}, 'third form 0.3');
invalid( 1, {type=>'int', attrs=>{min=>10}}, 'third form 0.4');
valid  (10, {type=>'int', attr_hashes=>[{min=>10}]}, 'third form 0.5');
invalid( 1, {type=>'int', attr_hashes=>[{min=>10}]}, 'third form 0.6');
valid  (15, {type=>'int', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 0.7');
invalid(10, {type=>'int', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 0.8');
# NOTE: def key of third form is tested in 06-schema.t
dies_ok(sub { $ds->validate( 1, {type=>'int', foo=>1}) }, 'third form unknown key');

$ds = new Data::Schema;
invalid(15, {def=>{even=>[int=>{divisible_by=>2}]}, type=>'even', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 1.1', $ds);
valid  (12, {def=>{even=>[int=>{divisible_by=>2}]}, type=>'even', attr_hashes=>[{min=>10}], attrs=>{divisible_by=>3}}, 'third form 1.2', $ds);
dies_ok(sub { $ds->validate(2, 'even') }, 'third form 1.3: "even" is still unknown after previous validation');

valid  ( 2, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.1', $ds);
invalid( 1, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.2', $ds);
invalid(-2, {def=>{even=>[int=>{divisible_by=>2}], positive_even=>[even=>{min=>0}]},
             type=>'positive_even'}, 'third form 2.3', $ds);
dies_ok(sub {$ds->validate(2, 'even')}, 'third form 2.4: "even" is still unknown after previous validation');
dies_ok(sub {$ds->validate(2, 'even')}, 'third form 2.5: "positive_even" is still unknown after previous validation');

my $sch = {def=>{
                 even=>[int=>{divisible_by=>2}],
                 positive_even=>[even=>{min=>0}],
                 pe=>"positive_even",
                 array_of_pe=>[array=>{of=>'pe'}],
                },
           type=>'array_of_pe'};
invalid(2    , $sch, 'third form 3.1', $ds);
valid  ([]   , $sch, 'third form 3.2', $ds);
valid  ([2]  , $sch, 'third form 3.3', $ds);
invalid([-2] , $sch, 'third form 3.4', $ds);
dies_ok(sub{$ds->validate( 2, 'even')}, 'third form 2.5: "even" is still unknown after previous validation');
dies_ok(sub{$ds->validate( 2, 'positive_even')}, 'third form 2.6: "even" is still unknown after previous validation');
dies_ok(sub{$ds->validate( 2, 'pe')}, 'third form 2.7: "pe" is still unknown after previous validation');
dies_ok(sub{$ds->validate([], 'array_of_pe')}, 'third form 2.8: "array_of_pe" is still unknown after previous validation');

dies_ok(sub{valid(1, {type=>"int", def=>{"int"=>"int"}})}, 'third form: optional definition 1');
valid(1, {type=>"int", def=>{"?int"=>"int"}}, 'third form: optional definition 2');

# _pos_as_str escapes whitespaces
is($ds->_pos_as_str(["a", "b ", " c", "  d "]), "a/b_/_c/_d_", "_pos_as_str and whitespace");

# attr: name beginning with _ will be ignored
invalid(1, [int=>{   min =>2}], 'attr beginning with _ 1');
invalid(1, [int=>{ "^min"=>2}], 'attr beginning with _ 2');
valid  (1, [int=>{  _min =>2}], 'attr beginning with _ 3');
valid  (1, [int=>{"^_min"=>2}], 'attr beginning with _ 4');
