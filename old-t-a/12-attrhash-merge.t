#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 56;
use Data::Schema;

valid  (2,  [int=>{divisible_by=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 2.1');
valid  (3,  [int=>{divisible_by=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 2.2');
valid  (1,  [int=>{divisible_by=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 2.3');
invalid(1.1,[int=>{divisible_by=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 2.4');

valid  (2, [int=>{one_of=>[2]}=>{"+one_of"=>[3]}], 'multiple attrhash 3.1');
valid  (3, [int=>{one_of=>[2]}=>{"+one_of"=>[3]}], 'multiple attrhash 3.2');
invalid(0, [int=>{one_of=>[2]}=>{"+one_of"=>[3]}], 'multiple attrhash 3.3');

invalid(2, [int=>{is=>2}=>{"*is"=>3}], 'multiple attrhash 4.1');
valid  (3, [int=>{is=>2}=>{"*is"=>3}], 'multiple attrhash 4.2');
invalid(0, [int=>{is=>2}=>{"*is"=>3}], 'multiple attrhash 4.3');

valid  (2,  [int=>{'^divisible_by'=>2}=>{"divisible_by"=>3}], 'multiple attrhash 5.1 (keep left attr)');
invalid(3,  [int=>{'^divisible_by'=>2}=>{"divisible_by"=>3}], 'multiple attrhash 5.2 (keep left attr)');
valid  (6,  [int=>{'^divisible_by'=>2}=>{"divisible_by"=>3}], 'multiple attrhash 5.3 (keep left attr)');

valid  (2,  [int=>{'^divisible_by'=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 5.4 (keep left attr)');
invalid(3,  [int=>{'^divisible_by'=>2}=>{"!divisible_by"=>3}], 'multiple attrhash 5.5 (keep left attr)');

my $sch = [
    "hash",
    {  keys =>{a=>"int"  , b=>"int" ,   c =>"int",                   , "^f"=>"int"  ,   g=>"int"   }},
    {"*keys"=>{a=>"array",              c =>"int", d=>"int"          ,  "f"=>"array", "^g"=>"array"}},
    {"*keys"=>{            b=>"hash", "!c"=>"int",         , e=>"int",  "f"=>"hash" ,  "g"=>"hash" }},
];
invalid({a=>1 }, $sch, 'merge 3: a replaced by 2: invalid');
valid  ({a=>[]}, $sch, 'merge 3: a replaced by 2: valid');
invalid({b=>1 }, $sch, 'merge 3: b replaced by 3: invalid');
valid  ({b=>{}}, $sch, 'merge 3: b replaced by 3: valid');
invalid({c=>1 }, $sch, 'merge 3: c removed by 3');
valid  ({d=>1 }, $sch, 'merge 3: d new from 2');
valid  ({e=>1 }, $sch, 'merge 3: e new from 3');
invalid({f=>[]}, $sch, 'merge 3: f keep from 1: invalid 1');
invalid({f=>{}}, $sch, 'merge 3: f keep from 1: invalid 2');
valid  ({f=>1 }, $sch, 'merge 3: f keep from 1: valid');
valid  ({g=>[]}, $sch, 'merge 3: g keep from 2: valid');
invalid({g=>{}}, $sch, 'merge 3: g keep from 2: invalid 1');
invalid({g=>1 }, $sch, 'merge 3: g keep from 2: invalid 2');

