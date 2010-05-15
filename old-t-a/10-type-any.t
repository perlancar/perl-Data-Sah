#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 12;
use Data::Schema;

# any is either. we are just testing here that it will accept any kind
# of data.

valid(undef, 'any', 'undef');
valid(1, 'any', 'num');
valid('', 'any', 'str');
valid([], 'any', 'array');
valid({}, 'any', 'hash');
valid(Data::Schema->new, 'any', 'obj');


