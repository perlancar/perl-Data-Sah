#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah qw(gen_validator);
use Test::More 0.98;

my $sah = Data::Sah->new;

my @tests = (
    {schema=>["obj*"], input=>""  , valid=>0},
    {schema=>["obj*"], input=>[]  , valid=>0},
    {schema=>["obj*"], input=>{}  , valid=>0},
    {schema=>["obj*"], input=>$sah, valid=>1},

    {schema=>["obj*", isa=>"Exporter"], input=>$sah, valid=>1},
    {schema=>["obj*", isa=>"Foo"], input=>$sah, valid=>0},
    {schema=>["obj*", "!isa"=>"Foo"], input=>$sah, valid=>1},

    {schema=>["obj*", can=>"get_compiler"], input=>$sah, valid=>1},
    {schema=>["obj*", "can&"=>[qw/get_compiler gen_validator/]],
     input=>$sah, valid=>1},
    {schema=>["obj*", "can&"=>[qw/get_compiler foo/]],
     input=>$sah, valid=>0},
    {schema=>["obj*", "can|"=>[qw/get_compiler foo/]],
     input=>$sah, valid=>1},
);

for my $test (@tests) {
    my $v = gen_validator($test->{schema});
    if ($test->{valid}) {
        ok($v->($test->{input}), $test->{name});
    } else {
        ok(!$v->($test->{input}), $test->{name});
    }
}
done_testing();
