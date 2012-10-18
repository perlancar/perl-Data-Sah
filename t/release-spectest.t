#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use Data::Sah::Simple qw(gen_validator);
use File::chdir;
use FindBin qw($Bin);
use Test::More 0.98;
use YAML::Syck qw(LoadFile);
$YAML::Syck::ImplicitTyping = 1;

plan skip_all => "Only enabled under RELEASE_TESTING=1"
    unless $ENV{RELEASE_TESTING};

my $dir;
for my $d (grep {defined} (
    $ENV{SAH_SPECTEST_DIR}, ".", "spectest",
    "$Bin/spectest", "$Bin/../spectest")) {
    #diag "Trying $d ...";
    if ((-d $d) && (-f "$d/00-normalize_schema.yaml")) {
        $dir = $d;
        diag "spectest dir = $dir";
        last;
    }
}
die "Can't find spectest dir, try setting SAH_SPECTEST_DIR" unless $dir;
$CWD = $dir;

my $sah = Data::Sah->new;

my @tests;
if (@ARGV) {
    @tests = @ARGV;
} elsif ($ENV{PERL_SAH_SPECTEST_TESTS}) {
    @tests = split /,\s*|\s+/, $ENV{PERL_SAH_SPECTEST_TESTS}
}

for my $file ("00-normalize_schema.yaml") {
    next unless !@tests || $file ~~ @tests;
    subtest $file => sub {
        my $yaml = LoadFile($file);
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
            };
        }
    };
}

for my $file ("01-merge_clause_sets.yaml") {
    next unless !@tests || $file ~~ @tests;
    subtest $file => sub {
        my $yaml = LoadFile($file);
        for my $test (@{ $yaml->{tests} }) {
            subtest $test->{name} => sub {
                eval {
                    is_deeply($sah->_merge_clause_sets(@{ $test->{input} }),
                              $test->{result}, "result");
                };
                my $eval_err = $@;
                if ($test->{dies}) {
                    ok($eval_err, "dies");
                } else {
                    ok(!$eval_err, "doesn't die")
                        or diag $eval_err;
                }
            };
        }
    };
}

for my $file (<10-type-*.yaml>) {
    next unless !@tests || $file ~~ @tests;
    subtest $file => sub {
        my $yaml = LoadFile($file);
        for my $test (@{ $yaml->{tests} }) {
            subtest $test->{name} => sub {
                my $v = gen_validator($test->{schema});
                if ($test->{valid}) {
                    ok($v->($test->{input}), "valid");
                } else {
                    ok(!$v->($test->{input}), "invalid");
                }
            };
        }
    };
}

done_testing();
