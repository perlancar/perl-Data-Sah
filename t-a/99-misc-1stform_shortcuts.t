#!perl -T

use lib './t'; do 'testlib.pl';
use strict;
use warnings;
use Test::More tests => 49;
use Data::Schema;

my %data_parse = (
    'a' => 'a',
    #'()' => undef,
    '(a)' => 'a',
    '( ( a ) )' => 'a',

    'a|b' => [either => {of=>['a','b']}],
    'a|(b)' => [either => {of=>['a','b']}],
    'a | b' => [either => {of=>['a','b']}],
    'a|b|c|d' => [either => {of=>['a','b','c','d']}],
    'a&b' => [all => {of=>['a','b']}],
    'a&(b)' => [all => {of=>['a','b']}],
    'a & b' => [all => {of=>['a','b']}],
    'a&b&c&d' => [all => {of=>['a','b','c','d']}],
    'a*' => [a => {set=>1}],
    '(a)*' => [a => {set=>1}],
    '(a|b)*' => [either => {of=>['a','b'], set=>1}],

    #'[]' => undef,
    'a[]' => [array => {of=>'a'}],
      'a[][]' => [array => {of=>[array=>{of=>'a'}]}],
    '(a*)[]' => [array => {of=>[a=>{set=>1}]}],
      'a*[]' => [array => {of=>[a=>{set=>1}]}],
    '((int*)[])*' => [array => {of=>[int=>{set=>1}], set=>1}],
      'int*[]*' => [array => {of=>[int=>{set=>1}], set=>1}],
    'a*|b*' => [either => {of=>[[a=>{set=>1}], [b=>{set=>1}]]}],
    '(a*|b*)*' => [either => {of=>[[a=>{set=>1}], [b=>{set=>1}]], set=>1}],
    'a[]&b[]' => [all => {of=>[[array=>{of=>'a'}], [array=>{of=>'b'}]]}],
    '(a|b)[]' => [array => {of => [either => {of=>['a','b']}]}],
    '((a|b)*)[]' => [array => {of => [either => {of=>['a','b'], set=>1}]}],
      '(a|b)*[]' => [array => {of => [either => {of=>['a','b'], set=>1}]}],

    '[a,b]' => [array=>{elems=>['a','b']}],
    '[a*,(b|c)]' => [array=>{elems=>[[a=>{set=>1}],[either=>{of=>['b','c']}]]}],
    '[a*,b*,c*]*' => [array=>{elems=>[[a=>{set=>1}], [b=>{set=>1}], [c=>{set=>1}]], set=>1}],
    '([a*,b*,c*])*' => [array=>{elems=>[[a=>{set=>1}], [b=>{set=>1}], [c=>{set=>1}]], set=>1}],
    '[a*, b* , c*][]' => [array => {of=>[array=>{elems=>[[a=>{set=>1}], [b=>{set=>1}], [c=>{set=>1}]]}]}],
    '([a*,b*,c*]*)[]' => [array => {of=>[array=>{elems=>[[a=>{set=>1}], [b=>{set=>1}], [c=>{set=>1}]], set=>1}]}],

    #'{}' => undef,
    '{k1=>int}' => [hash => {keys=>{k1=>'int'}}],
    '{k1 => int}' => [hash => {keys=>{k1=>'int'}}],
    '{k1=>int}*' => [hash => {keys=>{k1=>'int'}, set=>1}],
    '{k1 => int*}' => [hash => {keys=>{k1=>[int=>{set=>1}]}}],
    '{* => str}' => [hash => {values_of=>'str'}],
    #'{"*" => str}' => ,
    '{k1=>int, k2=>str[], k3=>(int*|float*)}' => [hash=>{keys=>{k1=>'int', k2=>[array=>{of=>'str'}],
                                                                k3=>[either=>{of=>[[int=>{set=>1}],
                                                                                   [float=>{set=>1}]]}]
                                                            }}],
);

my $ds = new Data::Schema;

for (keys %data_parse) {
    is_deeply($ds->_parse_shortcuts($_), $data_parse{$_}, "parse_shortcuts '$_'");
}

my @data_normalize = (
    ['int*',
     {type=>'int', attr_hashes=>[{set=>1}], def=>{}}, "scalar 1"],
    ['int[]',
     {type=>'array', attr_hashes=>[{of=>'int'}], def=>{}}, "scalar 2"],

    [['int*', {set=>1}],
     {type=>'int', attr_hashes=>[{set=>1}], def=>{}}, "array 1"],
    [['int*', {set=>0}],
     {type=>'int', attr_hashes=>[{set=>0}], def=>{}}, "array 2"],
    [['int*', {minlen=>2}],
     {type=>'int', attr_hashes=>[{set=>1, minlen=>2}], def=>{}}, "array 3"],
    [['int*', {minlen=>2}, {set=>0}],
     {type=>'int', attr_hashes=>[{set=>1, minlen=>2}, {set=>0}], def=>{}}, "array 4"],

    [{type=>'int*', },
     {type=>'int', attr_hashes=>[{set=>1}], def=>{}}, "hash 1"],
    [{type=>'int*', attrs=>{set=>0}},
     {type=>'int', attr_hashes=>[{set=>0}], def=>{}}, "hash 1b"],
    [{type=>'int*', attr_hashes=>[{set=>0}]},
     {type=>'int', attr_hashes=>[{set=>0}], def=>{}}, "hash 2"],
    [{type=>'int*', attr_hashes=>[{minlen=>3}]},
     {type=>'int', attr_hashes=>[{set=>1, minlen=>3}], def=>{}}, "hash 3"],
    [{type=>'int*', attr_hashes=>[{minlen=>3}, {set=>0}]},
     {type=>'int', attr_hashes=>[{set=>1, minlen=>3}, {set=>0}], def=>{}}, "hash 4"],
);

for (@data_normalize) {
    is_deeply($ds->normalize_schema($_->[0]), $_->[1], "normalize_schema '$_->[2]'");
}

