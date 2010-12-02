#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 104;
use Data::Schema qw(Schema::Schema);

my $dss = $Data::Schema::Schema::Schema::DS_SCHEMAS->{schema};

invalid([int => {"a "=>1}], $dss, "attrhash: invalid attr name: invalid character");
invalid([int => {"1a"=>1}], $dss, "attrhash: invalid attr name: invalid character");
invalid([int => {("a"x65)=>1}], $dss, "attrhash: invalid attr name: too long");
valid  ([int => {"_a123"=>1}], $dss, "attrhash: valid attr name: begins with underscore");
my @prefixes = ('', '^', '+', '-', '*', '.');
for my $prefix (@prefixes) {
    invalid([int => {"$prefix" =>1}], $dss, "attrhash: invalid attr name: no name/suffix: (prefix=$prefix)");
}
for my $prefix (@prefixes) {
    for my $suffix (qw/warn err warnmsg errmsg comment note/) {
        valid([int => {"$prefix:$suffix" =>1}], $dss, "attrhash: attrless suffix: $suffix (prefix=$prefix)");
    }
}
for my $prefix (@prefixes) {
    valid([int => {"${prefix}min"=>1}], $dss, "attrhash: suffixless (prefix=$prefix)");
}
