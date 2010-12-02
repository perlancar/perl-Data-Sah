#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 54;
use Test::Exception;
use Data::Schema;

my $ds = Data::Schema->new;

invalid(undef, [int=>{set=>1}], 'default 0');

valid  (undef, [int=>{set=>1, default=>1}], 'default 1');
valid  (    2, [int=>{set=>1, default=>1}], 'default 2');
invalid(undef, [int=>{set=>1, default=>1, min=>2}], 'default 3');
valid  (    2, [int=>{set=>1, default=>1, min=>2}], 'default 4');

# some more complex default
invalid(undef, [hash=>{set=>1, default=> 1}], 'default ref 1');
invalid(undef, [hash=>{set=>1, default=>[]}], 'default ref 2');
valid  (undef, [hash=>{set=>1, default=>{}}], 'default ref 3');

invalid(undef, [hash=>{set=>1, minlen=>1, of=>"array", default=>{     }}], 'default ref 4');
invalid(undef, [hash=>{set=>1, minlen=>1, of=>"array", default=>{a=> 1}}], 'default ref 5');
valid  (undef, [hash=>{set=>1, minlen=>1, of=>"array", default=>{a=>[]}}], 'default ref 6');

# default is processed from leftmost attrhash first, as with every other attr
invalid(undef, [int=>{set=>1, default=>1, min=>2}, {default=>2}], '2 attrhash 1');
valid  (undef, [int=>{set=>1, default=>2, min=>2}, {default=>2}], '2 attrhash 2');
valid  (undef, [int=>{set=>1, default=>2, min=>2}, {default=>1}], '2 attrhash 3');

invalid(undef, [int=>{set=>1, default=>1}, {default=>2, min=>2}], '2 attrhash 1b');
valid  (undef, [int=>{set=>1, default=>2}, {default=>2, min=>2}], '2 attrhash 2b');
valid  (undef, [int=>{set=>1, default=>2}, {default=>1, min=>2}], '2 attrhash 3b');

# some merging tests

valid  (undef, [int=>{set=>1, default=>1, min=>2}, {'*default'=>2}], 'merge replace 1');
invalid(undef, [int=>{set=>1, default=>2, min=>2}, {'*default'=>1}], 'merge replace 2');

invalid(undef, [int=>{set=>1, default=>1, min=>2}, {'!default'=>2}], 'merge delete 1');
valid  (undef, [int=>{        default=>1, min=>2}, {'!default'=>2}], 'merge delete 1');

invalid(undef, [int=>{        default=> 4, min=>2}, {'+default'=>-3}], 'merge add 1');
valid  (undef, [int=>{set=>1, default=>-1, min=>2}, {'+default'=> 3}], 'merge add 2');

invalid(undef, [int=>{        default=> 4, min=>2}, {'-default'=> 3}], 'merge subtract 1');
valid  (undef, [int=>{set=>1, default=>-1, min=>2}, {'-default'=>-3}], 'merge subtract 2');

invalid(undef, [int=>{set=>1, '^default'=>1, min=>2}, {default=>2}], 'merge keep 1');
valid  (undef, [int=>{set=>1, '^default'=>2, min=>2}, {default=>1}], 'merge keep 2');


