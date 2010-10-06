#!perl -T

use lib './t'; require 'testlib.pl';
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Data::Schema;

my $ds;
my $res;

$ds = new Data::Schema;

$res = ds_validate(1, 'int');
ok($res && $res->{success}, '(deprecated) procedural interface 1');
$res = ds_validate("a", 'int');
ok($res && !$res->{success} && @{$res->{errors}}, '(deprecated) procedural interface 2');

# $foo->perl

# $foo->compile

# $foo->human

# attribute merging works

# normalize_schema works

# attr: name beginning with _ will be ignored
