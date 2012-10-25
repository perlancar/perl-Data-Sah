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
my @specfiles;
{
    local $CWD = $dir;
    @specfiles = <*.yaml>;
}

my $sah = Data::Sah->new;

#my @files = split /\s+/, ($ENV{SAH_SPECTEST_FILES} // "");
my @files = @ARGV;

for my $file ("00-normalize_schema.yaml") {
    next unless !@files || $file ~~ @files;
    subtest $file => sub {
        my $yaml = LoadFile("$dir/$file");
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
    next unless !@files || $file ~~ @files;
    subtest $file => sub {
        my $yaml = LoadFile("$dir/$file");
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

for my $file (grep /^10-type-/, @specfiles) {
    next unless !@files || $file ~~ @files;
    subtest $file => sub {
        my $yaml = LoadFile("$dir/$file");
        for my $test (@{ $yaml->{tests} }) {
            subtest $test->{name} => sub {
                note "schema: ", explain($test->{schema}),
                    ", input: ", explain($test->{input});
                my $vbool = gen_validator($test->{schema});
                if ($test->{valid}) {
                    ok($vbool->($test->{input}), "valid (vrt=bool)");
                } else {
                    ok(!$vbool->($test->{input}), "invalid (vrt=bool)");
                }

                my $vstr = gen_validator($test->{schema},
                                         {validator_return_type=>'str'});
                if ($test->{valid}) {
                    is($vstr->($test->{input}), "", "valid (vrt=str)");
                } else {
                    like($vstr->($test->{input}), qr/\S/, "invalid (vrt=str)");
                }

                my $vfull = gen_validator($test->{schema},
                                          {validator_return_type=>'full'});
                my $res = $vfull->($test->{input});
                is(ref($res), 'HASH', "validator (vrt=full) returns hash");
                my $errors = $test->{errors} // ($test->{valid} ? 0 : 1);
                is(~~@{ $res->{errors} // [] }, $errors,
                   "errors (vrt=full)") or diag explain $res;

            };
        }
    };
}

done_testing();
