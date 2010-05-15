#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 232;
use Data::Schema;

valid(1, 'int', 'int 1');
valid(0, 'int', 'int 2');
valid(-1, 'int', 'int 3');
invalid(1.1, 'int', 'float');
invalid('a', 'int', 'str');
invalid([], 'int', 'array');
invalid({}, 'int', 'hash');

valid(1, 'integer', 'alias 1');

valid(undef, 'int', 'undef');

test_comparable('int', 1, -2, 3, -4);
test_sortable('int', -4, 5, 10);

# mod
invalid(10, [int=>{mod=>[3,2]}], 'mod 1');
valid(11, [int=>{mod=>[3,2]}], 'mod 2');

# divisible_by
invalid(11, [int=>{divisible_by=>3}], 'divisible_by 1');
valid  (12, [int=>{divisible_by=>3}], 'divisible_by 2');
invalid( 7, [int=>{divisible_by=>[3,4]}], 'divisible_by 3');
invalid( 6, [int=>{divisible_by=>[3,4]}], 'divisible_by 4');
invalid( 8, [int=>{divisible_by=>[3,4]}], 'divisible_by 5');
valid  (12, [int=>{divisible_by=>[3,4]}], 'divisible_by 6');
for (qw(not_divisible_by indivisible_by)) {
    valid  (11, [int=>{$_=>3}], "$_ 1");
    invalid(12, [int=>{$_=>3}], "$_ 2");
    valid  ( 7, [int=>{$_=>[3,4]}], "$_ 3");
    invalid( 6, [int=>{$_=>[3,4]}], "$_ 4");
    invalid( 8, [int=>{$_=>[3,4]}], "$_ 5");
    invalid(12, [int=>{$_=>[3,4]}], "$_ 6");
}

test_deps('int', 1, {min=>1}, {min=>2});


