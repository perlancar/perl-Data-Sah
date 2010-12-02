#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 4*1; # 4*3
use Data::Schema;

# i do not want to test each and every attribute here, as it just
# repeats what's on the translation file (which can be tweaked a
# lot). a missed translation is not that fatal. we just need to make
# sure that the mechanism & formatting works.

my $ds = new Data::Schema;

my @humans = (
    ['int',
     ['integer'],
     'Integer.',
     '<p>Integer.</p>'],

    ['int*',
     ['integer', 'must be provided'],
     'Integer. Must be provided.',
     '<p>Integer. Must be provided.</p>'],

    ['int[]',
     ['array', ['elements must be', ['integer']]],
     'Array. Elements must be integer.',
     '<p>Array. Elements must be integer.</p>'],

    [[array=>{of=>'int*'}],
     ['array', ['elements must be', ['integer', 'must be provided']]],
     'Array. Elements must be: integer, must be provided',
     '<p>Array. Elements must be: integer, must be provided</p>'],
);
for (@humans) {
    my $test_name = ref($_->[0]) ? Data::Schema::__dump($_->[0]) : $_->[0];
    is_deeply($ds->_human($_->[0]), $_->[1], "_human $test_name");
    #is($ds->human($_->[0]), $_->[2], "human text $test_name", 'text');
    #is($ds->human($_->[0]), $_->[3], "human html $test_name", 'html');
}
