#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Test::Exception;
use Test::More 0.98;
use Test::Warn;

subtest "compile()" => sub {
    my $sah = Data::Sah->new;
    my $plc = $sah->get_compiler("perl");

    dies_ok {
        $plc->compile(schema=>[int => {foo=>1}]);
    } 'on_unhandled_clause=die (default)';

    warning_like {
        $plc->compile(schema=>[int => {foo=>1}],
                      on_unhandled_clause=>'warn');
    } qr/foo/, 'on_unhandled_clause=warn';

    lives_ok {
        $plc->compile(schema=>[int => {foo=>1}],
                      on_unhandled_clause=>'ignore');
    } 'on_unhandled_clause=ignore';

    dies_ok {
        $plc->compile(schema=>[int => {"min.foo"=>1}]);
    } 'on_unhandled_attr=die (default)';

    warning_like {
        $plc->compile(schema=>[int => {"min.foo"=>1}],
                      on_unhandled_attr=>'warn');
    } qr/min\.foo/, 'on_unhandled_attr=warn';

    lives_ok {
        $plc->compile(schema=>[int => {"min.foo"=>1}],
                      on_unhandled_attr=>'ignore');
    } 'on_unhandled_attr=ignore';

};

done_testing();
