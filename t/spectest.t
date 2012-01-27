#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use File::chdir;
use FindBin qw($Bin);
use Test::More 0.98;
use YAML::Syck qw(LoadFile);
$YAML::Syck::ImplicitTyping = 1;

my $dir;
for ("$Bin/spectest", "$Bin/../spectest") {
    if (-d) {
        $dir = $_;
        last;
    }
}
die "Can't find spectest dir" unless $dir;
$CWD = $dir;

my $sah = Data::Sah->new;

subtest "normalize" => sub {
    my $yaml = LoadFile("00-normalize.yaml");
    for my $test (@{ $yaml->{tests} }) {
        subtest $test->{name} => sub {
            eval {
                is_deeply($sah->normalize_schema($test->{input}),
                          $test->{result}, "result");
            };
            my $eval_err = $@;
            if ($test->{dies}) {
                ok($eval_err, "dies");
            } else {
                ok(!$eval_err, "doesn't die")
                    or diag $eval_err;
            }
            done_testing();
        };
    }
    done_testing();
};

done_testing();
