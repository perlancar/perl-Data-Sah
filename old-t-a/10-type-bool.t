#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 104;
use Data::Schema;

valid(1, 'bool', 'bool 1');
valid("true", 'bool', 'bool 2');
valid(0, 'bool', 'bool 3');
valid("", 'bool', 'bool 4');
invalid([], 'bool', 'bool 5');
invalid({}, 'bool', 'bool 6');

valid(1, 'boolean', 'alias 1');

valid(undef, 'bool', 'undef');

valid(1, [bool => {is=>1}], 'is 1');
valid(1, [bool => {is=>"true"}], 'is 2');
invalid(0, [bool => {is=>"true"}], 'is 3');

valid(0, [bool => {isnt=>1}], 'isnt 1');
valid('', [bool => {isnt=>"true"}], 'isnt 2');
invalid(1, [bool => {isnt=>"true"}], 'isnt 3');

valid('yes', [bool => {min=>'true'}], 'min 1');
invalid('', [bool => {min=>'true'}], 'min 2');
valid('', [bool => {max=>''}], 'max 1');
invalid(1, [bool => {max=>''}], 'max 2');

test_deps('bool', 0, {is=>0}, {is=>1});


