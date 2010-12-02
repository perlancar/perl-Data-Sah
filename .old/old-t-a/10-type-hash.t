#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 1016;
use Data::Schema;

valid({}, 'hash', 'basic 1');
valid({1, 2}, 'hash', 'basic 2');

# not hash
invalid([], 'hash', 'array');
invalid('123', 'hash', 'str');
invalid(\1, 'hash', 'refscalar');

# required
valid({}, [hash => {required => 1}], 'required 1');

test_len('hash', {a=>1}, {a=>1, b=>2}, {a=>1, b=>2, c=>3}); # 36

test_comparable('hash', {a=>1}, {b=>1}, {c=>1}, {d=>1}); # 26

for (qw(keys_match allowed_keys_regex)) {
    valid({a=>1}, [hash => {$_=>'^\w+$'}], "$_ 1");
    invalid({a=>1, 'b '=>2}, [hash => {$_=>'^\w+$'}], "$_ 2");
}

for (qw(keys_not_match forbidden_keys_regex)) {
    valid({'a '=>1}, [hash => {$_=>'^\w+$'}], "$_ 1");
    invalid({'a '=>1, b=>2}, [hash => {$_=>'^\w+$'}], "$_ 2");
}

for (qw(values_match allowed_values_regex)) {
    valid({1=>'a'}, [hash => {$_=>'^\w+$'}], "$_ 1");
    invalid({1=>'a', 2=>'b '}, [hash => {$_=>'^\w+$'}], "$_ 2");
}

for (qw(values_not_match forbidden_values_regex)) {
    valid({1=>'a '}, [hash => {$_=>'^\w+$'}], "$_ 1");
    invalid({1=>'a ', 2=>'b'}, [hash => {$_=>'^\w+$'}], "$_ 2");
}

# required_keys
valid({a=>1, b=>1, c=>1}, [hash => {required_keys=>[qw/a b/]}], "required_keys 1");
valid({a=>1, b=>1, c=>undef}, [hash => {required_keys=>[qw/a b/]}], "required_keys 2");
valid({a=>1, b=>undef, c=>1}, [hash => {required_keys=>[qw/a b/]}], "required_keys 3");
valid({a=>undef, b=>1, c=>1}, [hash => {required_keys=>[qw/a b/]}], "required_keys 4");
invalid({b=>1, c=>1}, [hash => {required_keys=>[qw/a b/]}], "required_keys 5");
invalid({c=>undef}, [hash => {required_keys=>[qw/a b/]}], "required_keys 6");
valid({}, [hash => {required_keys=>[]}], "required_keys 7");

for (qw(required_keys_regex)) {
    valid  ({a=>1    , b=>1    }, [hash => {$_=>'^[a]$'}], "$_ 1");
    valid  ({a=>1    , b=>undef}, [hash => {$_=>'^[a]$'}], "$_ 2");
    valid  ({a=>1    ,         }, [hash => {$_=>'^[a]$'}], "$_ 3");
    valid  ({a=>undef, b=>1    }, [hash => {$_=>'^[a]$'}], "$_ 4");
    valid  ({a=>undef, b=>undef}, [hash => {$_=>'^[a]$'}], "$_ 5");
    valid  ({a=>undef,         }, [hash => {$_=>'^[a]$'}], "$_ 6");
    invalid({          b=>1    }, [hash => {$_=>'^[a]$'}], "$_ 7");
    invalid({          b=>undef}, [hash => {$_=>'^[a]$'}], "$_ 8");
    invalid({                  }, [hash => {$_=>'^[a]$'}], "$_ 9");
}

for (qw(all_keys keys_of)) {
    my $sch = [hash=>{$_=>'int'}];
    valid({}, $sch, "$_ 1");
    valid({1=>1, 0=>0, -1=>-1}, $sch, "$_ 2");
    invalid({a=>1}, $sch, "$_ 3");
}

for (qw(all_values of values_of)) {
    my $sch = [hash=>{$_=>'int'}];
    valid({}, $sch, "$_ 1");
    valid({a=>1, b=>0, c=>-1}, $sch, "$_ 2");
    invalid({a=>1, b=>"a"}, $sch, "$_ 3");
}

for (qw(some_of)) {
    # at least one int=>int, exactly 2 str=>str, at most one int=>array. note: str is also int
    my $sch = [hash=>{$_=>[ [int=>int=>1,-1], [str=>str=>2,2], [int=>array=>0,1] ]}];
    invalid([], $sch, "$_ 1");

    valid({1=>1, a=>"a", 3=>[]}, $sch, "$_ 2");

    valid({1=>1, 2=>2, 3=>[]}, $sch, "$_ 3");
    valid({1=>1, 2=>2}, $sch, "$_ 4");
    valid({1=>1, a=>"a"}, $sch, "$_ 5");

    invalid({a=>"a", b=>"b", 3=>[]}, $sch, "$_ 6"); # too few int=>int
    invalid({1=>1, 3=>[]}, $sch, "$_ 7"); # too few str=>str
    invalid({1=>1, 2=>2, a=>"a", 3=>[]}, $sch, "$_ 8"); # too many str=>str
    invalid({1=>1, a=>"a", 3=>[], 4=>[]}, $sch, "$_ 9"); # too many int=>array

    invalid({1=>1.1, a=>"a", 3=>[]}, $sch, "$_ 10"); # invalid int=>int
    invalid({1.1=>1, a=>"a", 3=>[]}, $sch, "$_ 11"); # invalid int=>int
    invalid({1=>1, a=>[], 3=>[]}, $sch, "$_ 12"); # invalid str=>str
    valid({1=>1, a=>"a", 3.1=>[]}, $sch, "$_ 13"); # invalid int=>array, but still valid
    valid({1=>1, a=>"a", 3=>{}}, $sch, "$_ 14"); # invalid int=>array, but still valid

    invalid({}, $sch, "$_ 15");
}

for (qw(keys)) {
    my $dse = new Data::Schema(config=>{allow_extra_hash_keys=>1});

    my $sch = [hash=>{$_=>{i=>'int', s=>'str', s2=>[str=>{minlen=>2}]}}];
    valid({}, $sch, "$_ 1.1");
    invalid({k=>1}, $sch, "$_ 1.2");
    valid  ({k=>1}, $sch, "$_ 1.2 (allow_extra_hash_keys=1)", $dse);
    valid({i=>1}, $sch, "$_ 1.3");
    invalid({i=>"a"}, $sch, "$_ 1.4");
    valid({i=>1, s=>''}, $sch, "$_ 1.5");
    invalid({i=>1, s=>[]}, $sch, "$_ 1.6");
    invalid({i=>1, s=>'', s2=>''}, $sch, "$_ 1.7");
    valid({i=>1, s=>'', s2=>'ab'}, $sch, "$_ 1.8");

    $sch = [hash=>{$_=>{h=>"hash", h2=>[hash=>{minlen=>1, $_=>{hi2=>[int=>{min=>2}]}}]}}];
    invalid({h=>1}, $sch, "$_ 2.1");
    valid({h=>{}}, $sch, "$_ 2.2");
    invalid({h=>{}, h2=>{}}, $sch, "$_ 2.3");
    invalid({h2=>{j=>1}}, $sch, "$_ 2.4");
    valid  ({h2=>{j=>1}}, $sch, "$_ 2.4 (allow_extra_hash_keys=1)", $dse);
    invalid({h2=>{hi2=>1}}, $sch, "$_ 2.5");
    valid({h2=>{hi2=>2}}, $sch, "$_ 2.6");
}

for (qw(keys_one_of allowed_keys)) {
    my $sch = [hash=>{$_=>["a", "b"]}];
    valid({}, $sch, "$_ 1");
    valid({a=>1, b=>1}, $sch, "$_ 2");
    invalid({a=>1, b=>1, c=>1}, $sch, "$_ 3");
}

for (qw(values_one_of allowed_values)) {
    my $sch = [hash=>{$_=>[1, 2, [3]]}];
    valid({}, $sch, "$_ 1");
    valid({a=>1, b=>2, c=>[3]}, $sch, "$_ 2");
    invalid({a=>3}, $sch, "$_ 3");
}

for (qw(keys_regex)) {
    my $sch = [hash=>{$_=>{'^i\d*$'=>'int'}}];
    valid({}, $sch, "$_ 1");
    valid({i=>1, i2=>2}, $sch, "$_ 2");
    invalid({i=>1, i2=>"a"}, $sch, "$_ 3");
    invalid({j=>1}, $sch, "$_ 4");
}

test_deps('hash', {a=>0.1, b=>2.3}, {of=>"float"}, {of=>"int"});

for (qw(element_deps element_dep elem_deps elem_dep key_deps key_dep)) {
    my $sch;
    # second totally dependent on first
    $sch = [hash=>{$_ => [[a=>[int=>{set=>1}], b=>[int=>{set=>1}]],
                          [a=>[int=>{set=>0}], b=>[int=>{set=>0}]] ]}];
    valid  ({},                  $sch, "$_ 1.1");
    valid  ({a=>undef,b=>undef}, $sch, "$_ 1.2");
    invalid({a=>1,b=>undef},     $sch, "$_ 1.3");
    invalid({a=>undef,b=>1},     $sch, "$_ 1.4");
    valid  ({a=>1,b=>1},         $sch, "$_ 1.5");
    # no match
    valid  ({a=>"a",b=>undef},   $sch, "$_ 1.6");
    valid  ({a=>"a",b=>1},       $sch, "$_ 1.7");
    valid  ({a=>"a",b=>"a"},     $sch, "$_ 1.8");

    # mutually exclusive
    $sch = [hash=>{$_ => [[a=>[int=>{set=>1}], b=>[int=>{set=>0}]],
                          [a=>[int=>{set=>0}], b=>[int=>{set=>1}]] ]}];
    valid  ({},                  $sch, "$_ 2.1");
    invalid({a=>undef,b=>undef}, $sch, "$_ 2.2");
    valid  ({a=>1,b=>undef},     $sch, "$_ 2.3");
    valid  ({a=>undef,b=>1},     $sch, "$_ 2.4");
    invalid({a=>1,b=>1},         $sch, "$_ 2.5");
    # no match
    valid  ({a=>"a",b=>undef},   $sch, "$_ 2.6");
    valid  ({a=>"a",b=>1},       $sch, "$_ 2.7");
    valid  ({a=>"a",b=>"a"},     $sch, "$_ 2.8");

    # regex
    $sch = [hash=>{ $_ => [['.*', [int=>{min=>1}], '.*', [int=>{min=>2}]]] }];
    valid  ({          }, $sch, "$_ regex 1a");

    # -- all matches left
    invalid({a=>1      }, $sch, "$_ regex 1b");
    valid  ({a=>2      }, $sch, "$_ regex 1c");
    invalid({a=>1,b=> 1}, $sch, "$_ regex 1d");
    invalid({a=>1,b=> 2}, $sch, "$_ regex 1e");
    valid  ({a=>2,b=> 2}, $sch, "$_ regex 1f");

    # -- some matches left, doesn't matter because ALL on the left must match
    valid  ({a=>0,b=> 1}, $sch, "$_ regex 1g");
    valid  ({a=>0,b=> 2}, $sch, "$_ regex 1h");

    # -- none matches left, doesn't matter
    valid  ({a=>0      }, $sch, "$_ regex 1i");
    valid  ({a=>0,b=>-1}, $sch, "$_ regex 1j");
}

# allow_extra_keys
for ([keys => {a=>"int"}], [keys_regex => {a=>"int"}]) {
    valid  ({a=>1}       , [hash=>{$_->[0] => $_->[1]                     }], "allow_extra_keys $_->[0] 1a");
    invalid({a=>1,b=>2}  , [hash=>{$_->[0] => $_->[1]                     }], "allow_extra_keys $_->[0] 1b");
    valid  ({a=>1}       , [hash=>{$_->[0] => $_->[1], allow_extra_keys=>0}], "allow_extra_keys $_->[0] 2a");
    invalid({a=>1,b=>2}  , [hash=>{$_->[0] => $_->[1], allow_extra_keys=>0}], "allow_extra_keys $_->[0] 2b");
    valid  ({a=>1}       , [hash=>{$_->[0] => $_->[1], allow_extra_keys=>1}], "allow_extra_keys $_->[0] 3a");
    valid  ({a=>1,b=>2}  , [hash=>{$_->[0] => $_->[1], allow_extra_keys=>1}], "allow_extra_keys $_->[0] 3b");
    invalid({a=>"a",b=>2}, [hash=>{$_->[0] => $_->[1], allow_extra_keys=>1}], "allow_extra_keys $_->[0] 3c");
    # overrides validator config setting
    my $dse = Data::Schema->new(config=>{allow_extra_hash_keys=>1});
    valid  ({a=>1,b=>2}  , [hash=>{$_->[0] => $_->[1]                     }], "allow_extra_keys $_->[0] 4a", $dse);
    invalid({a=>1,b=>2}  , [hash=>{$_->[0] => $_->[1], allow_extra_keys=>0}], "allow_extra_keys $_->[0] 4b", $dse);
}

# conflicting & codependent keys
for (qw(conflicting_keys)) {
    my $sch = [hash => {$_ => [["A", "a"], ["B", "b"]]}];
    valid  ({                       }, $sch, "$_ 1");
    valid  ({A=>1                   }, $sch, "$_ 2");
    valid  ({a=>1                   }, $sch, "$_ 3");
    valid  ({B=>1                   }, $sch, "$_ 4");
    valid  ({b=>1                   }, $sch, "$_ 5");
    valid  ({A=>1, B=>1             }, $sch, "$_ 6");
    valid  ({A=>1, b=>1             }, $sch, "$_ 7");
    valid  ({a=>1, B=>1             }, $sch, "$_ 8");
    valid  ({a=>1, b=>1             }, $sch, "$_ 9");
    invalid({A=>1, a=>1             }, $sch, "$_ 10");
    invalid({B=>1, b=>1             }, $sch, "$_ 11");
    invalid({A=>1, a=>1, B=>1       }, $sch, "$_ 12");
    invalid({A=>1, a=>1, b=>1       }, $sch, "$_ 13");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 14");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 15");
    invalid({A=>1, a=>1, b=>1, B=>1 }, $sch, "$_ 16");

    $sch = [hash => {$_ => [[1, 2, 3]]}];
    valid  ({                      }, $sch, "$_ b1");
    valid  ({                  4=>4}, $sch, "$_ b2");
    valid  ({1=>1                  }, $sch, "$_ b3");
    valid  ({1=>1,             4=>4}, $sch, "$_ b4");
    valid  ({      2=>2,           }, $sch, "$_ b5");
    valid  ({      2=>2,       4=>4}, $sch, "$_ b6");
    valid  ({            3=>3,     }, $sch, "$_ b7");
    valid  ({            3=>3, 4=>4}, $sch, "$_ b8");
    invalid({1=>1, 2=>2,           }, $sch, "$_ b9");
    invalid({1=>1, 2=>2,       4=>4}, $sch, "$_ b10");
    invalid({      2=>2, 3=>3      }, $sch, "$_ b11");
    invalid({      2=>2, 3=>3, 4=>4}, $sch, "$_ b12");
    invalid({1=>1,       3=>3,     }, $sch, "$_ b13");
    invalid({1=>1,       3=>3, 4=>4}, $sch, "$_ b14");
    invalid({1=>1, 2=>2, 3=>3,     }, $sch, "$_ b15");
    invalid({1=>1, 2=>2, 3=>3, 4=>4}, $sch, "$_ b16");
}
for (qw(conflicting_keys_regex)) {
    my $sch = [hash => {$_ => [["^A.*", "^a.*"], ["^B.*", "^b.*"]]}];
    valid  ({                       }, $sch, "$_ 0");
    valid  ({A=>1                   }, $sch, "$_ 1");
    valid  ({a=>1                   }, $sch, "$_ 2");
    valid  ({B=>1                   }, $sch, "$_ 3");
    valid  ({b=>1                   }, $sch, "$_ 4");
    valid  ({A=>1, B=>1             }, $sch, "$_ 5");
    valid  ({A=>1, b=>1             }, $sch, "$_ 6");
    valid  ({a=>1, B=>1             }, $sch, "$_ 7");
    valid  ({a=>1, b=>1             }, $sch, "$_ 8");
    invalid({A=>1, a=>1             }, $sch, "$_ 9");
    invalid({B=>1, b=>1             }, $sch, "$_ 10");
    invalid({A=>1, a=>1, B=>1       }, $sch, "$_ 11");
    invalid({A=>1, a=>1, b=>1       }, $sch, "$_ 12");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 13");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 14");
    invalid({A=>1, a=>1, b=>1, B=>1 }, $sch, "$_ 15");

    valid  ({A1=>1, A2=>1        }, $sch, "$_ re1");
    valid  ({a1=>1, a2=>1        }, $sch, "$_ re2");
    invalid({a1=>1, A1=>1        }, $sch, "$_ re3");
    invalid({a1=>1, A1=>1, A2=>1 }, $sch, "$_ re4");
    invalid({a1=>1, a2=>1, A1=>1 }, $sch, "$_ re5");

    $sch = [hash => {$_ => [["^1.*", "^2.*", "^3.*"]]}];
    valid  ({                      }, $sch, "$_ b1");
    valid  ({                  4=>4}, $sch, "$_ b2");
    valid  ({1=>1                  }, $sch, "$_ b3");
    valid  ({1=>1,             4=>4}, $sch, "$_ b4");
    valid  ({      2=>2,           }, $sch, "$_ b5");
    valid  ({      2=>2,       4=>4}, $sch, "$_ b6");
    valid  ({            3=>3,     }, $sch, "$_ b7");
    valid  ({            3=>3, 4=>4}, $sch, "$_ b8");
    invalid({1=>1, 2=>2,           }, $sch, "$_ b9");
    invalid({1=>1, 2=>2,       4=>4}, $sch, "$_ b10");
    invalid({      2=>2, 3=>3      }, $sch, "$_ b11");
    invalid({      2=>2, 3=>3, 4=>4}, $sch, "$_ b12");
    invalid({1=>1,       3=>3,     }, $sch, "$_ b13");
    invalid({1=>1,       3=>3, 4=>4}, $sch, "$_ b14");
    invalid({1=>1, 2=>2, 3=>3,     }, $sch, "$_ b15");
    invalid({1=>1, 2=>2, 3=>3, 4=>4}, $sch, "$_ b16");
}
for (qw(codependent_keys)) {
    my $sch = [hash => {$_ => [["A", "a"], ["B", "b"]]}];
    valid  ({                       }, $sch, "$_ 0");
    invalid({A=>1                   }, $sch, "$_ 1");
    invalid({a=>1                   }, $sch, "$_ 2");
    invalid({B=>1                   }, $sch, "$_ 3");
    invalid({b=>1                   }, $sch, "$_ 4");
    invalid({A=>1, B=>1             }, $sch, "$_ 5");
    invalid({A=>1, b=>1             }, $sch, "$_ 6");
    invalid({a=>1, B=>1             }, $sch, "$_ 7");
    invalid({a=>1, b=>1             }, $sch, "$_ 8");
    valid  ({A=>1, a=>1             }, $sch, "$_ 9");
    valid  ({B=>1, b=>1             }, $sch, "$_ 10");
    invalid({A=>1, a=>1, B=>1       }, $sch, "$_ 11");
    invalid({A=>1, a=>1, b=>1       }, $sch, "$_ 12");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 13");
    invalid({A=>1, b=>1, b=>1       }, $sch, "$_ 14");
    valid  ({A=>1, a=>1, B=>1, b=>1 }, $sch, "$_ 15");

    $sch = [hash => {$_ => [[1, 2, 3]]}];
    valid  ({                      }, $sch, "$_ b1");
    valid  ({                  4=>4}, $sch, "$_ b2");
    invalid({1=>1                  }, $sch, "$_ b3");
    invalid({1=>1,             4=>4}, $sch, "$_ b4");
    invalid({      2=>2,           }, $sch, "$_ b5");
    invalid({      2=>2,       4=>4}, $sch, "$_ b6");
    invalid({            3=>3,     }, $sch, "$_ b7");
    invalid({            3=>3, 4=>4}, $sch, "$_ b8");
    invalid({1=>1, 2=>2,           }, $sch, "$_ b9");
    invalid({1=>1, 2=>2,       4=>4}, $sch, "$_ b10");
    invalid({      2=>2, 3=>3      }, $sch, "$_ b11");
    invalid({      2=>2, 3=>3, 4=>4}, $sch, "$_ b12");
    invalid({1=>1,       3=>3,     }, $sch, "$_ b13");
    invalid({1=>1,       3=>3, 4=>4}, $sch, "$_ b14");
    valid  ({1=>1, 2=>2, 3=>3,     }, $sch, "$_ b15");
    valid  ({1=>1, 2=>2, 3=>3, 4=>4}, $sch, "$_ b16");
}
for (qw(codependent_keys_regex)) {
    my $sch = [hash => {$_ => [["^A.*", "^a.*"], ["^B.*", "^b.*"]]}];
    valid  ({                       }, $sch, "$_ 0");
    invalid({A=>1                   }, $sch, "$_ 1");
    invalid({a=>1                   }, $sch, "$_ 2");
    invalid({B=>1                   }, $sch, "$_ 3");
    invalid({b=>1                   }, $sch, "$_ 4");
    invalid({A=>1, B=>1             }, $sch, "$_ 5");
    invalid({A=>1, b=>1             }, $sch, "$_ 6");
    invalid({a=>1, B=>1             }, $sch, "$_ 7");
    invalid({a=>1, b=>1             }, $sch, "$_ 8");
    valid  ({A=>1, a=>1             }, $sch, "$_ 9");
    valid  ({B=>1, b=>1             }, $sch, "$_ 10");
    invalid({A=>1, a=>1, B=>1       }, $sch, "$_ 11");
    invalid({A=>1, a=>1, b=>1       }, $sch, "$_ 12");
    invalid({A=>1, b=>1, B=>1       }, $sch, "$_ 13");
    invalid({A=>1, b=>1, b=>1       }, $sch, "$_ 14");
    valid  ({A=>1, a=>1, B=>1, b=>1 }, $sch, "$_ 15");

    invalid({A1=>1, A2=>1        }, $sch, "$_ re1");
    invalid({a1=>1, a2=>1        }, $sch, "$_ re2");
    valid  ({a1=>1, A1=>1        }, $sch, "$_ re3");
    valid  ({a1=>1, A1=>1, A2=>1 }, $sch, "$_ re4");
    valid  ({a1=>1, a2=>1, A1=>1 }, $sch, "$_ re5");

    $sch = [hash => {$_ => [["^1.*", "^2.*", "^3.*"]]}];
    valid  ({                      }, $sch, "$_ b1");
    valid  ({                  4=>4}, $sch, "$_ b2");
    invalid({1=>1                  }, $sch, "$_ b3");
    invalid({1=>1,             4=>4}, $sch, "$_ b4");
    invalid({      2=>2,           }, $sch, "$_ b5");
    invalid({      2=>2,       4=>4}, $sch, "$_ b6");
    invalid({            3=>3,     }, $sch, "$_ b7");
    invalid({            3=>3, 4=>4}, $sch, "$_ b8");
    invalid({1=>1, 2=>2,           }, $sch, "$_ b9");
    invalid({1=>1, 2=>2,       4=>4}, $sch, "$_ b10");
    invalid({      2=>2, 3=>3      }, $sch, "$_ b11");
    invalid({      2=>2, 3=>3, 4=>4}, $sch, "$_ b12");
    invalid({1=>1,       3=>3,     }, $sch, "$_ b13");
    invalid({1=>1,       3=>3, 4=>4}, $sch, "$_ b14");
    valid  ({1=>1, 2=>2, 3=>3,     }, $sch, "$_ b15");
    valid  ({1=>1, 2=>2, 3=>3, 4=>4}, $sch, "$_ b16");
}
