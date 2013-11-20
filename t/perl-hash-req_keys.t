#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch

use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin";

require "testlib.pl";

use Data::Sah qw(gen_validator);

my @tests = (
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{a => undef, b => 0, c => 1}, valid=>1},
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{a => undef, b => 0, c => 1, d => 1}, valid=>1},
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{a => undef, b => 0, c => 1, d => undef}, valid=>1},
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{}, valid=>0},
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{c => 1}, valid=>0},
  {schema=>['hash*', req_keys => ['a', 'b', 'c']], input=>{a => 1, b => 1}, valid=>0},
);

my @human_tests = (
  {schema=>['hash*', req_keys => ['a']], result => 'hash, must have following key(s): a'},
  {schema=>['hash*', req_keys => ['a','b']], result => 'hash, must have following key(s): a, b'}
);

for my $test (@human_tests) {
  test_human(lang=>"en_US", %$test);
}

for my $test (@tests) {
  my $v = gen_validator($test->{schema});
  if ($test->{valid}) {
    ok($v->($test->{input}), $test->{name});
  } else {
    ok(!$v->($test->{input}), $test->{name});
  }
}
done_testing();


