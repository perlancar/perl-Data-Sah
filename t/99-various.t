#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah qw(gen_validator);
use Test::Exception;
use Test::More 0.98;
#use Test::Warn;

my $sah = Data::Sah->new;
my $plc = $sah->get_compiler("perl");

subtest "[2014-01-03 ] req_keys clash between \$_ and \$dt" => sub {
    # req_keys generates this code: ... sub {!exists($dt\->{\$_})} ... When $dt
    # is '$_' there will be clash, so we need to assign $dt to another variable
    # first.
    my $v = gen_validator([array => of => [hash => req_keys => ["a"]]]);
    lives_and { ok( $v->([]      )) } "[] validates";
    lives_and { ok(!$v->(["a"]   )) } "['a'] doesn't validate";
    lives_and { ok(!$v->([{}]    )) } "[{}] doesn't validate";
    lives_and { ok(!$v->([{b=>1}])) } "[{b=>1}] doesn't validate";
    lives_and { ok( $v->([{a=>1}])) } "[{a=>1}] validates";
};

done_testing();
