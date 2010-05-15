#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 192;
use Test::Exception;
use Data::Schema;

our $TEST_COMPILED;

my $ds = new Data::Schema;
for (($TEST_COMPILED == 2 ? 1 : 0), ($TEST_COMPILED > 0 ? 1 : 0)) {
    $ds->config->compile($_);
    my $res;
    my $a = ['foo '];
    $res = $ds->validate($a, [array=>{of=>[str=>{prefilters=>['trim']}]}]);
    is_deeply($res->{result}, ['foo' ], "validation has no side effect a (array, compile=$_)");
    is_deeply($a            , ['foo '], "validation has no side effect b (array, compile=$_)");
    my $h = {'a '=>'foo '};
    $res = $ds->validate($h, [hash=>{of=>[str=>{prefilters=>['trim']}]}]);
    is_deeply($res->{result}, {'a '=>'foo' }, "validation has no side effect a (hash, compile=$_)");
    is_deeply($h            , {'a '=>'foo '}, "validation has no side effect b (hash, compile=$_)");
}

valid  ('foo ', [str=>{prefilters =>['trim'], len=>3}], 'prefilters vs postfilters 1a');
invalid('foo ', [str=>{postfilters=>['trim'], len=>3}], 'prefilters vs postfilters 1b');

###

validate_is(["a "], [array=>{prefilters=>['trim']}], ["a "], 'filter skips unsuitable data (trim)');

validate_is('foo ', [str=>{postfilters=>['trim'], len=>4}], 'foo', 'postfilters 1');

for (qw(trim)) {
    validate_is(' foo ', [str => {prefilters=>[$_], len => 3}], 'foo', "$_ on scalar");
    validate_is([' foo ', ' bar '], [array => {prefilters=>[$_], of => [str => {len => 3}]}], ['foo', 'bar'], "$_ on array (of)");
    validate_is([' foo '], [array => {prefilters=>[$_], elements => [[str => {len => 3}]]}], ['foo'], "$_ on array (elems)");
    validate_is({'a '=>' foo ', 'b'=>' bar '}, [hash => {prefilters=>[$_], of => [str => {len => 3}]}], {'a '=>'foo', b=>'bar'}, "$_ on hash (of)");
    validate_is({'a '=>' foo '}, [hash => {prefilters=>[$_], keys => {'a '=>[str => {len => 3}]}}], {'a '=>'foo'}, "$_ on hash (keys)");
}

for (qw(trim_trailing rtrim)) {
    validate_is(' foo ', [str => {prefilters=>[$_], len => 4}], ' foo', "$_ on scalar");
    validate_is([' foo ', ' bar '], [array => {prefilters=>[$_], of => [str => {len => 4}]}], [' foo', ' bar'], "$_ on array (of)");
    validate_is([' foo '], [array => {prefilters=>[$_], elements => [[str => {len => 4}]]}], [' foo'], "$_ on array (elems)");
    validate_is({'a '=>' foo ', 'b'=>' bar '}, [hash => {prefilters=>[$_], of => [str => {len => 4}]}], {'a '=>' foo', b=>' bar'}, "$_ on hash (of)");
    validate_is({'a '=>' foo '}, [hash => {prefilters=>[$_], keys => {'a '=>[str => {len => 4}]}}], {'a '=>' foo'}, "$_ on hash (keys)");
}

for (qw(trim_leading ltrim)) {
    validate_is(' foo ', [str => {prefilters=>[$_], len => 4}], 'foo ', "$_ on scalar");
    validate_is([' foo ', ' bar '], [array => {prefilters=>[$_], of => [str => {len => 4}]}], ['foo ', 'bar '], "$_ on array (of)");
    validate_is([' foo '], [array => {prefilters=>[$_], elements => [[str => {len => 4}]]}], ['foo '], "$_ on array (elems)");
    validate_is({'a '=>' foo ', 'b'=>' bar '}, [hash => {prefilters=>[$_], of => [str => {len => 4}]}], {'a '=>'foo ', b=>'bar '}, "$_ on hash (of)");
    validate_is({'a '=>' foo '}, [hash => {prefilters=>[$_], keys => {'a '=>[str => {len => 4}]}}], {'a '=>'foo '}, "$_ on hash (keys)");
}

# as well as checking that {pre,post}filters accept filter in the form of [name, arg1, ...] instead of 'name'

for (qw(re_replace re_sub)) {
    validate_is('foo', [str => {prefilters =>[[$_ => 'o' => 'x']]}], 'fxx', "$_ (prefilters)");
    validate_is('foo', [str => {postfilters=>[[$_ => 'o' => 'x']]}], 'fxx', "$_ (postfilters)");
}

for (qw(re_replace_once re_sub_once)) {
    validate_is('foo', [str => {prefilters=>[[$_ => 'o' => 'x']]}], 'fxo', "$_");
}

for (qw(uc)) {
    validate_is('foo', [str => {prefilters=>[$_]}], 'FOO', "$_");
}

for (qw(lc)) {
    validate_is('FOO', [str => {prefilters=>[$_]}], 'foo', "$_");
}

for (qw(ucfirst)) {
    validate_is('foo', [str => {prefilters=>[$_]}], 'Foo', "$_");
}

for (qw(lcfirst)) {
    validate_is('FOO', [str => {prefilters=>[$_]}], 'fOO', "$_");
}

for (qw(split)) {
    validate_is('a,b,c', [array => {prefilters=>[[$_ => qr/,\s*/]]}], [qw/a b c/], "$_");
}

for (qw(join)) {
    validate_is([qw/a b c/], [str => {prefilters=>[[$_ => ", "]]}], "a, b, c", "$_");
}

for (qw(sort)) {
    validate_is([qw/b a c/], [array => {prefilters=>[$_   ]}], [qw/a b c/], "$_");
    validate_is([qw/b a c/], [array => {prefilters=>["r$_"]}], [qw/c b a/], "r$_"); # rsort
}

for (qw(nsort)) {
    validate_is([qw/1 10 2/], [array => {prefilters=>[$_   ]}], [qw/1 2 10/], "$_");
    validate_is([qw/1 10 2/], [array => {prefilters=>["r$_"]}], [qw/10 2 1/], "r$_"); # rnsort
}

for (qw(cisort)) {
    validate_is([qw/B a c/], [array => {prefilters=>[$_   ]}], [qw/a B c/], "$_");
    validate_is([qw/B a c/], [array => {prefilters=>["r$_"]}], [qw/c B a/], "r$_"); # rcisort
}
