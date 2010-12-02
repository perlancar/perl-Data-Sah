#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;
use Data::Schema;

package MyType1;
use Any::Moose;
extends 'Data::Schema::Type::Base';
sub chkarg_attr_bar { 1  };
sub validt_attr_bar { 1  };
sub emitpl_attr_bar { '' };

package main;

my $ds = Data::Schema->new;

$ds->register_type(foo => MyType1->new);
valid  (1,     'foo',           'foo 1', $ds);
valid  (1,     [foo=>{set=>1}], 'foo 2', $ds);
invalid(undef, [foo=>{set=>1}], 'foo 3', $ds);
valid  (undef, [foo=>{bar=>1}], 'foo 4', $ds);
valid  (1,     [foo=>{bar=>1}], 'foo 5', $ds);
dies_ok(sub { $ds->validate(1, [foo=>{deps=>[]}]) }, 'unknown attribute');


