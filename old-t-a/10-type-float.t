#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 190;
use Data::Schema;

valid(1, 'float', 'float 1');
valid(0, 'float', 'float 2');
valid(-1, 'float', 'float 3');
valid(1.1, 'float', 'float 4');
invalid('a', 'float', 'str');
invalid([], 'float', 'array');
invalid({}, 'float', 'hash');

valid(undef, 'float', 'undef');

test_comparable('float', 1, -2.1, 3.1, -4.1);
test_sortable('float', -4.1, 5.1, 10.1);

test_deps('float', 1.1, {min=>1}, {min=>2});


