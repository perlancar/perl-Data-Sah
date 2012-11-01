#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah;
use File::chdir;
use File::ShareDir::Tarball;
use FindBin qw($Bin);
use Test::More 0.98;
use YAML::Syck qw(LoadFile);
$YAML::Syck::ImplicitTyping = 1;

my $dir = File::ShareDir::Tarball::dist_dir("Sah");
$dir && (-d $dir) or die "Can't find spectest, have you installed Sah?";
(-f "$dir/spectest/00-normalize_schema.yaml")
    or die "Something's wrong, spectest doesn't contain the correct files";

my @specfiles;
{
    local $CWD = "$dir/spectest";
    @specfiles = <*.yaml>;
}

my $sah = Data::Sah->new;

#my @files = split /\s+/, ($ENV{SAH_SPECTEST_FILES} // "");
my @files = @ARGV;

for my $file ("00-normalize_schema.yaml") {
    next unless !@files || $file ~~ @files;
    subtest $file => sub {
        my $yaml = LoadFile("$dir/spectest/$file");
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
        my $yaml = LoadFile("$dir/spectest/$file");
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
        diag "Loading $file ...";
        my $yaml = LoadFile("$dir/spectest/$file");
        for my $test (@{ $yaml->{tests} }) {
            subtest $test->{name} => sub {
                note "schema: ", explain($test->{schema}),
                    ", input: ", explain($test->{input});
                my $vbool = $sah->gen_validator($test->{schema});
                if ($test->{valid}) {
                    ok($vbool->($test->{input}), "valid (vrt=bool)");
                } else {
                    ok(!$vbool->($test->{input}), "invalid (vrt=bool)");
                }

                my $vstr = $sah->gen_validator($test->{schema},
                                               {return_type=>'str'});
                if ($test->{valid}) {
                    is($vstr->($test->{input}), "", "valid (vrt=str)");
                } else {
                    like($vstr->($test->{input}), qr/\S/, "invalid (vrt=str)");
                }

                my $vfull = $sah->gen_validator($test->{schema},
                                                {return_type=>'full'});
                my $res = $vfull->($test->{input});
                is(ref($res), 'HASH', "validator (vrt=full) returns hash");
                my $errors = $test->{errors} // ($test->{valid} ? 0 : 1);
                is(~~@{ $res->{errors} // [] }, $errors,
                   "errors (vrt=full)") or diag explain $res;
                my $warnings = $test->{warnings} // 0;
                is(~~@{ $res->{warnings} // [] }, $warnings,
                   "warnings (vrt=full)") or diag explain $res;
            };
        }
    };
}

done_testing();
