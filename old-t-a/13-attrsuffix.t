#!perl -T

use lib './t'; do 'testlib.pm';
use strict;
use warnings;
use Test::More tests => 308;
use Test::Exception;
use Data::Schema;
use Clone qw/clone/;

# unknown
dies_ok(sub {ds_validate(1, [int=>{"max:foo"=>1}])}, 'unknown');

# comment/note, has no effect whatsoever
for my $a (qw(comment note)) {
    for my $b ('min', 'max', 'foo', '') {
        for (undef, "", 0, 1, -1, "int", [], {}) {
            my $r = defined($_) ? (ref($_) ? ref($_) : ($_ eq '' ? "emptystr" : $_)) : "undef";
            valid  (1, [int=>{min=>1, "$b:$a"=>1}], "$b:$a $r valid");
            invalid(0, [int=>{min=>1, "$b:$a"=>1}], "$b:$a $r invalid");
        }
    }
}

# ATTR:errmsg
invalid(
    10,
    [int=>{"min"=>200, "min:errmsg"=>"don't be so cheap!"}],
    "ATTR:errmsg",
    undef,
    sub {
        my ($res, $test_name, $ds) = @_;
        like($res->{errors}[0], qr/cheap/, "$test_name errmsg");
    }
);

# ATTR:warnmsg
valid(
    10,
    [int=>{"min:warn"=>200, "min:warnmsg"=>"teu nanaon sih, tapi ih meni pedit nya?"}],
    "ATTR:warnmsg",
    undef,
    sub {
        my ($res, $test_name, $ds) = @_;
        like($res->{warnings}[0], qr/nanaon.+pedit/, "$test_name warnmsg");
    }
);

# :errmsg & :warnmsg
my $sch = [int=>{min=>2,
                 "divisible_by:warn"=>2,
                 one_of=>[2,3,4], "one_of:warn"=>[3,4]}];
my $sch_e  = clone($sch  ); $sch_e ->[1]{":errmsg"}  = "GENERIC_ERR";
my $sch_w  = clone($sch  ); $sch_w ->[1]{":warnmsg"} = "GENERIC_WARN";
my $sch_we = clone($sch_w); $sch_we->[1]{":errmsg"}  = "GENERIC_ERR";
invalid(1, $sch, "no :errmsg & no :warnmsg", undef,
        sub {
            my ($res, $test_name, $ds) = @_;
            is(scalar(@{ $res->{errors}   }), 2, "$test_name numerr");
            is(scalar(@{ $res->{warnings} }), 2, "$test_name numwarn");
        }
    );
invalid(1, $sch_e, "with :errmsg & no :warnmsg", undef,
        sub {
            my ($res, $test_name, $ds) = @_;
            is(scalar(@{ $res->{errors}   }), 1, "$test_name numerr");
            is(scalar(@{ $res->{warnings} }), 2, "$test_name numwarn");
            like($res->{errors}[0], qr/GENERIC_ERR/, "$test_name errmsg");
        }
    );
invalid(1, $sch_w, "no :errmsg & with :warnmsg", undef,
        sub {
            my ($res, $test_name, $ds) = @_;
            is(scalar(@{ $res->{errors}   }), 2, "$test_name numerr");
            is(scalar(@{ $res->{warnings} }), 1, "$test_name numwarn");
            like($res->{warnings}[0], qr/GENERIC_WARN/, "$test_name warnmsg");
        }
    );
invalid(1, $sch_we, "with :errmsg & with :warnmsg", undef,
        sub {
            my ($res, $test_name, $ds) = @_;
            is(scalar(@{ $res->{errors}   }), 1, "$test_name numerr");
            is(scalar(@{ $res->{warnings} }), 1, "$test_name numwarn");
            like($res->{errors}[0], qr/GENERIC_ERR/, "$test_name errmsg");
            like($res->{warnings}[0], qr/GENERIC_WARN/, "$test_name warnmsg");
        }
    );

# :warn
$sch_w = clone($sch); $sch_w->[1]{":warn"} = 0;
valid(1, $sch_w, ":warn", undef,
      sub {
          my ($res, $test_name, $ds) = @_;
          is(scalar(@{ $res->{warnings} }), 4, "$test_name numwarn");
      }
  );

# :err
$sch_e = clone($sch); $sch_e->[1]{":err"} = 0;
invalid(1, $sch_e, ":err", undef,
        sub {
            my ($res, $test_name, $ds) = @_;
            is(scalar(@{ $res->{errors}   }), 2, "$test_name numerr");
            is(scalar(@{ $res->{warnings} }), 2, "$test_name numwarn");
        }
    );

# conflict between :warn & :err
$sch_we = clone($sch); $sch_we->[1]{":warn"} = $sch_we->[1]{":err"} = 0;
dies_ok(sub { test_validate(1, $sch_we, "dummy") }, ":warn & :err conflict");
