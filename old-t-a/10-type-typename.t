#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 100;
use Data::Schema;

valid  (undef, 'typename', 'undef 1');
invalid(undef, [typename=>{set=>1}], 'undef 2');

my @standard_types = qw(
    str
    string
    cistr   
    cistring
    bool    
    boolean 
    hash    
    array   
    object  
    obj     
    int     
    integer 
    float   
    either  
    or      
    any     
    all     
    and
    typename     
);
for (@standard_types) {
    valid  ($_, [typename => {known=>1}], "known $_ 1");
    invalid($_, [typename => {known=>0}], "known $_ 2");
}

invalid('foo', [typename=>{known=>1}], 'foo is unknown 1');
valid  ('foo', [typename=>{known=>0}], 'foo is unknown 2');

valid  ('foo', {def=>{foo=>"int"}, type=>'typename', attr_hashes=>[{known=>1}]}, 'foo becomes known in subschema 1');
invalid('foo', {def=>{foo=>"int"}, type=>'typename', attr_hashes=>[{known=>0}]}, 'foo becomes known in subschema 2');

invalid('foo', [typename=>{known=>1}], 'foo is unknown again 1');
valid  ('foo', [typename=>{known=>0}], 'foo is unknown again 2');

my $ds = Data::Schema->new;
my $res = $ds->register_schema_as_type({type=>"str", attr_hashes=>[], def=>{}}, "foo");
die "Can't register schema as type 'foo': $res->{error}" unless $res->{success};
valid  ('foo', [typename=>{isa_schema=>1}], 'isa_schema 1', $ds);
valid  ('int', [typename=>{known=>1, isa_schema=>0}], 'isa_schema 2', $ds);
invalid('bar', [typename=>{isa_schema=>1}], 'isa_schema 3a', $ds);
invalid('bar', [typename=>{isa_schema=>0}], 'isa_schema 3b', $ds);
