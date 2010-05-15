#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 630;
use Test::Differences;
use Data::Schema;

valid([], 'array', 'basic 1');
valid([1, 2], 'array', 'basic 2');

# not array
invalid({}, 'array', 'hash');
invalid('123', 'array', 'str');
invalid(\1, 'array', 'refscalar');

valid([], [array => {required => 1}], 'required 1');

test_len('array', [1], [1,2], [1,2,3]);

test_comparable('array', [1], [2], [3], [4]);

for (qw(all_elements all_element all_elems all_elem of)) {
    my $sch = [array=>{$_=>"int"}];
    valid([], $sch, "$_ 1");
    valid([1, 0, -1], $sch, "$_ 2");
    invalid([1, "a"], $sch, "$_ 3");
}

for (qw(some_of)) {
    # at least one int, exactly 2 strings, at most one array. note: str is also int
    my $sch = [array=>{$_=>[ [int=>1,-1], [str=>2,2], [array=>0,1] ]}];
    invalid([], $sch, "$_ 1");

    valid([1, "a", []], $sch, "$_ 2");

    valid([1, 2, []], $sch, "$_ 3");
    valid([1, 2], $sch, "$_ 4");
    valid([1, "a"], $sch, "$_ 5");

    invalid(["a", "a", []], $sch, "$_ 6"); # too few int
    invalid([1, []], $sch, "$_ 7"); # too few str
    invalid([1, 1, "a", []], $sch, "$_ 8"); # too many str
    invalid([1, "a", [], []], $sch, "$_ 9"); # too many array

    invalid([], $sch, "$_ 10");
}

for (qw(elements element elems elem)) {
    my $sch = [array=>{$_=>["int", "str", [str=>{minlen=>2}]]}];
    valid([], $sch, "$_ 1.1");
    valid([1], $sch, "$_ 1.2");
    invalid(["a"], $sch, "$_ 1.3");
    valid([1,""], $sch, "$_ 1.4");
    invalid([1,[]], $sch, "$_ 1.5");
    invalid([1,"",""], $sch, "$_ 1.6");
    valid([1,"","ab"], $sch, "$_ 1.7");

    $sch = [array=>{$_=>["array", [array=>{minlen=>1, $_=>[[int=>{min=>2}]]}]]}];
    invalid([1], $sch, "$_ 2.1");
    valid([[]], $sch, "$_ 2.2");
    invalid([[], []], $sch, "$_ 2.3");
    invalid([[], [1]], $sch, "$_ 2.4");
    valid([[], [2]], $sch, "$_ 2.5");
}

for (qw(
     elements_regex
     element_regex
     elems_regex
     elem_regex
     )) {
    my $sch = [array=>{$_=>{'^(0|1)$'=>'int'}}];
    valid([], $sch, "$_ 1");
    valid([1], $sch, "$_ 2");
    valid([1, 1], $sch, "$_ 3");
    invalid([1, "a"], $sch, "$_ 4");
    valid([1, 1, 1], $sch, "$_ 5");
    valid([1, 1, "a"], $sch, "$_ 6");
}

invalid([1, 1, 2], [array=>{unique=>1}], 'unique 1');
valid  ([1, 3, 2], [array=>{unique=>1}], 'unique 2');
valid  ([1, 1, 2], [array=>{unique=>0}], 'unique 3');
invalid([1, 3, 2], [array=>{unique=>0}], 'unique 4');

test_deps('array', [0.1, 2.3], {of=>"float"}, {of=>"int"});

for (qw(element_deps element_dep elem_deps elem_dep)) {
    my $sch;
    # second totally dependent on first
    $sch = [array=>{$_ => [[0=>[int=>{set=>1}], 1=>[int=>{set=>1}]],
                           [0=>[int=>{set=>0}], 1=>[int=>{set=>0}]] ]}];
    valid  ([],            $sch, "$_ 1.1");
    valid  ([undef,undef], $sch, "$_ 1.2");
    invalid([1,undef],     $sch, "$_ 1.3");
    invalid([undef,1],     $sch, "$_ 1.4");
    valid  ([1,1],         $sch, "$_ 1.5");
    # no match
    valid  (["a",undef],   $sch, "$_ 1.6");
    valid  (["a",1],       $sch, "$_ 1.7");
    valid  (["a","a"],     $sch, "$_ 1.8");

    # mutually exclusive
    $sch = [array=>{$_ => [[0=>[int=>{set=>1}], 1=>[int=>{set=>0}]],
                           [0=>[int=>{set=>0}], 1=>[int=>{set=>1}]] ]}];
    valid  ([],            $sch, "$_ 2.1");
    invalid([undef,undef], $sch, "$_ 2.2");
    valid  ([1,undef],     $sch, "$_ 2.3");
    valid  ([undef,1],     $sch, "$_ 2.4");
    invalid([1,1],         $sch, "$_ 2.5");
    # no match
    valid  (["a",undef],   $sch, "$_ 2.6");
    valid  (["a",1],       $sch, "$_ 2.7");
    valid  (["a","a"],     $sch, "$_ 2.8");

    $sch = [array=>{$_ => [ [0=>"int", 1=>[str=>{minlen=>2, match=>"[A-Z]"}]] ]}];
    invalid([0, "a"], 
	    $sch, 
	    "$_ passthru schema2 errors", 
	    undef, 
	    sub {
	      my ($res, $test_name, $ds) = @_;
	      is((scalar @{ $res->{errors} }), 2, "$test_name 2");
	    }
	   );
    # regex
    $sch = [array=>{ $_ => [['.*', [int=>{min=>1}], '.*', [int=>{min=>2}]]] }];
    valid  ([    ], $sch, "$_ regex 1a");

    # -- all matches left
    invalid([1   ], $sch, "$_ regex 1b");
    valid  ([2   ], $sch, "$_ regex 1c");
    invalid([1,1 ], $sch, "$_ regex 1d");
    invalid([1,2 ], $sch, "$_ regex 1e");
    valid  ([2,2 ], $sch, "$_ regex 1f");

    # -- some matches left, doesn't matter because ALL on the left must match
    valid  ([0, 1], $sch, "$_ regex 1g");
    valid  ([0, 2], $sch, "$_ regex 1h");

    # -- none matches left, doesn't matter
    valid  ([0   ], $sch, "$_ regex 1i");
    valid  ([0,-1], $sch, "$_ regex 1j");
}


