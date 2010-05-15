#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 48;
use Data::Schema qw(Schema::Schema);

my $dss = $Data::Schema::Schema::Schema::DS_SCHEMAS->{schema};

valid  ("int", $dss, "first form");
invalid("   ", $dss, "first form: invalid type name");
invalid("foo", $dss, "first form: unknown type");

invalid([], $dss, "second form: invalid");
valid  (["int"], $dss, "second form");
invalid(["   "], $dss, "second form: invalid type name");
invalid(["foo"], $dss, "second form: unknown type");

invalid([int => undef], $dss, "second form: attrhash: invalid 1");
invalid([int => 1    ], $dss, "second form: attrhash: invalid 2");
invalid([int => []   ], $dss, "second form: attrhash: invalid 3");
invalid([int => {},1 ], $dss, "second form: attrhash: invalid 4");
valid  ([int => {}   ], $dss, "second form: attrhash: empty");

invalid({}, $dss, "third form: missing key 'type'");
invalid({foo=>1}, $dss, "third form: unknown key");
valid  ({type=>"int"}, $dss, "third form: valid");
invalid({type=>"1a" }, $dss, "third form: invalid type name");
invalid({type=>"foo"}, $dss, "third form: unknown type");

invalid({type=>"int", attr_hashes=>undef, }, $dss, "third form: attrhashes: invalid 1");
invalid({type=>"int", attr_hashes=>{}     }, $dss, "third form: attrhashes: invalid 2");
invalid({type=>"int", attr_hashes=>[1]    }, $dss, "third form: attrhashes: invalid 3");
valid  ({type=>"int", attr_hashes=>[{}]   }, $dss, "third form: attrhashes: invalid 4");

valid  ({type=>"int", def=>undef}, $dss, "third form: empty def");
invalid({type=>"int", def=>1}, $dss, "third form: invalid def");
valid  ({type=>"int", def=>{}}, $dss, "third form: empty def 2");
