use 5.010;
use strict;
use warnings;
use FindBin qw($Bin);

use Capture::Tiny qw(tee_merged);
use Data::Sah;
use Data::Sah::JS qw();
use File::chdir;
use File::ShareDir ();
use File::ShareDir::Tarball ();
use File::Slurp::Tiny qw(read_file);
use File::Temp qw(tempfile);
use JSON;
use List::Util qw(first);
use String::Indent qw(indent);
use Test::Exception;
use Test::More 0.98;
use Version::Util qw(version_eq);

my $json = JSON->new->allow_nonref;

my $sah = Data::Sah->new;

# return true if all elements in $list1 are in $list2
sub all_match {
    no warnings 'experimental'; # smartmatch
    my ($list1, $list2) = @_;

    for (@$list1) {
        return 0 unless $_ ~~ @$list2;
    }
    1;
}

# return true if any element in $list1 is in $list2
sub any_match {
    no warnings 'experimental'; # smartmatch
    my ($list1, $list2) = @_;

    for (@$list1) {
        return 1 if $_ ~~ @$list2;
    }
    0;
}

# return true if none of the elements in $list1 is in $list2
sub none_match {
    no warnings 'experimental'; # smartmatch
    my ($list1, $list2) = @_;

    for (@$list1) {
        return 0 if $_ ~~ @$list2;
    }
    1;
}

sub run_spectest {
    no warnings 'experimental'; # smartmatch
    require Sah;

    my ($cname, $opts) = @_; # compiler name
    $opts //= {};

    my $dir;
    if (version_eq($Sah::VERSION, "0.9.27")) {
        # this version of Sah temporarily uses ShareDir instead of
        # ShareDir::Tarball due to garbled output problem of tarball.
        $dir = File::ShareDir::dist_dir("Sah");
    } else {
        $dir = File::ShareDir::Tarball::dist_dir("Sah");
    }
    $dir && (-d $dir) or die "Can't find spectest, have you installed Sah?";
    (-f "$dir/spectest/00-normalize_schema.json")
        or die "Something's wrong, spectest doesn't contain the correct files";

    my @specfiles;
    {
        local $CWD = "$dir/spectest";
        @specfiles = <*.json>;
    }

    # to test certain files only
    my @files;
    if ($ENV{TEST_SAH_SPECTEST_FILES}) {
        @files = split /\s*,\s*|\s+/, $ENV{TEST_SAH_SPECTEST_FILES};
    } else {
        @files = @ARGV;
    }

    # to test certain types only
    my @types;
    if ($ENV{TEST_SAH_SPECTEST_TYPES}) {
        @types = split /\s*,\s*|\s+/, $ENV{TEST_SAH_SPECTEST_TYPES};
    }

    # to test only tests that have all matching tags
    my @include_tags;
    if ($ENV{TEST_SAH_SPECTEST_INCLUDE_TAGS}) {
        @include_tags = split /\s*,\s*|\s+/,
            $ENV{TEST_SAH_SPECTEST_INCLUDE_TAGS};
    }

    # to skip tests that have all matching tags
    my @exclude_tags;
    if ($ENV{TEST_SAH_SPECTEST_EXCLUDE_TAGS}) {
        @exclude_tags = split /\s*,\s*|\s+/,
            $ENV{TEST_SAH_SPECTEST_EXCLUDE_TAGS};
    }

    my $should_skip_test = sub {
        my $t = shift;
        if ($opts->{skip_if}) {
            my $reason = $opts->{skip_if}->($t);
            return $reason if $reason;
        }
        if ($t->{tags} && @exclude_tags) {
            return "contains all excluded tags (".
                join(", ", @exclude_tags).")"
                    if all_match(\@exclude_tags, $t->{tags});
        }
        if (@include_tags) {
            return "does not contain all include tags (".
                join(", ", @include_tags).")"
                    if !all_match(\@include_tags, $t->{tags} // []);
        }
        "";
    };

    goto SKIP1 unless $cname eq 'perl';

    for my $file ("00-normalize_schema.json") {
        unless (!@files || $file ~~ @files) {
            diag "Skipping file $file";
            next;
        }
        subtest $file => sub {
            my $tspec = $json->decode(~~read_file("$dir/spectest/$file"));
            for my $test (@{ $tspec->{tests} }) {
                subtest $test->{name} => sub {
                    if (my $reason = $should_skip_test->($test)) {
                        plan skip_all => "Skipping test $test->{name}: $reason";
                        return;
                    }
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
            ok 1; # an extra dummy ok to pass even if all spectest is skipped
        };
    }

    for my $file ("01-merge_clause_sets.json") {
        unless (!@files || $file ~~ @files) {
            diag "Skipping file $file";
            next;
        }
        subtest $file => sub {
            my $tspec = $json->decode(~~read_file("$dir/spectest/$file"));
            for my $test (@{ $tspec->{tests} }) {
                subtest $test->{name} => sub {
                    if (my $reason = $should_skip_test->($test)) {
                        plan skip_all => "Skipping test $test->{name}: $reason";
                        return;
                    }
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
            ok 1; # an extra dummy ok to pass even if all spectest is skipped
        };
    }

  SKIP1:

    for my $file (grep /^10-type-/, @specfiles) {
        unless (!@files || $file ~~ @files) {
            diag "Skipping file $file";
            next;
        }
        subtest $file => sub {
            diag "Loading $file ...";
            my $tspec = $json->decode(~~read_file("$dir/spectest/$file"));
            note "Test version: ", $tspec->{version};
            my $tests = $tspec->{tests};
            if ($cname eq 'perl') {
                run_st_tests_perl(
                    $tests, { %$opts, _should_skip_test=>$should_skip_test });
            } elsif ($cname eq 'human') {
                run_st_tests_human(
                    $tests, { %$opts, _should_skip_test=>$should_skip_test });
            } elsif ($cname eq 'js') {
                run_st_tests_js(
                    $tests, { %$opts, _should_skip_test=>$should_skip_test });
            }
            ok 1; # an extra dummy ok to pass even if all spectest is skipped
        };
    } # file
}

sub run_st_tests_perl {
    my ($tests, $opts) = @_;
    for my $test (@$tests) {
        my $tname = "(tags=".join(", ", sort @{ $test->{tags} // [] }).
            ") $test->{name}";
        if ($opts->{_should_skip_test} &&
                (my $reason = $opts->{_should_skip_test}->($test))) {
            diag "Skipping test $tname: $reason";
            next;
        }
        note explain $test;
        subtest $tname => sub {
            run_st_test_perl($test);
        };
    }
}

sub run_st_tests_human {
    my ($tests, $opts) = @_;
    for my $test (@$tests) {
        my $tname = "(tags=".join(", ", sort @{ $test->{tags} // [] }).
            ") $test->{name}";
        if ($opts->{_should_skip_test} &&
                (my $reason = $opts->{_should_skip_test}->($test))) {
            diag "Skipping test $tname: $reason";
            next;
        }
        note explain $test;
        subtest $tname => sub {
            run_st_test_human($test);
        };
    }
}

sub run_st_tests_js {
    my ($tests, $opts) = @_;

    # we compile all the schemas (plus some control code) to a single js file
    # then execute it using nodejs. the js file is supposed to produce TAP
    # output.

    my $node_path = $opts->{node_path} // Data::Sah::JS::get_nodejs_path();
    my $js = $sah->get_compiler('js');

    my %names; # key: json(schema)
    my %counters; # key: type name

    my @js_code;

    # controller/tap code
    push @js_code, <<'_';
String.prototype.repeat = function(n) { return new Array(isNaN(n) ? 1 : ++n).join(this) }

// BEGIN TAP

var indent = "    "
var tap_indent_level = 2
var tap_counter = 0
var tap_num_nok = 0

function tap_esc(name) {
    return name.replace(/#/g, '\\#').replace(/\n/g, '\n' + indent.repeat(tap_indent_level+1) + '#')
}

function tap_print_oknok(is_ok, name) {
    if (!is_ok) tap_num_nok++
    console.log(
        indent.repeat(tap_indent_level) +
        (is_ok ? "ok " : "not ok ") +
        ++tap_counter +
        (name ? " - " + tap_esc(name) : "")
    )
}

function tap_print_summary() {
    if (tap_num_nok > 0) {
        console.log(indent.repeat(tap_indent_level) + '# ' + tap_num_nok + ' failed test(s)')
    }
    console.log(
        indent.repeat(tap_indent_level) + "1.." + tap_counter
    )
}

function ok(cond, name) {
    tap_print_oknok(cond, name)
}

function subtest(name, code) {
     var save_counter = tap_counter
     var save_num_nok = tap_num_nok

     tap_num_nok = 0
     tap_counter = 0
     tap_indent_level++
     code()
     tap_print_summary()
     tap_indent_level--

     tap_counter       = save_counter
     var save2_num_nok = tap_num_nok
     tap_num_nok = save_num_nok
     tap_print_oknok(save2_num_nok == 0, name)
}

function done_testing() {
    tap_print_summary()
}

// END TAP

var res;

_

  TEST:
    for my $test (@$tests) {
        my $tname = "(tags=".join(", ", sort @{ $test->{tags} // [] }).
            ") $test->{name}";
        if ($opts->{_should_skip_test} &&
                (my $reason = $opts->{_should_skip_test}->($test))) {
            diag "Skipping test $tname: $reason";
            next TEST;
        }
        my $k = $json->encode($test->{schema});
        my $ns = $sah->normalize_schema($test->{schema});
        $test->{nschema} = $ns;

        my $fn = $names{$k};
        if (!$fn) {
            $fn = "sahv_" . $ns->[0] . ++$counters{$ns->[0]};
            $names{$k} = $fn;

            push @js_code, "\n\n",
                indent("// ", "schema: " . $json->encode($ns)), "\n\n";

            for my $rt (qw/bool str full/) {
                my $code;
                eval {
                    $code = $js->expr_validator_sub(
                        schema => $ns,
                        schema_is_normalized => 1,
                        return_type => $rt,
                    );
                };
                my $err = $@;
                if ($test->{dies}) {
                    #note "schema = ", explain($ns);
                    ok($err, $tname);
                    next TEST;
                } else {
                    ok(!$err, "compile ok ($tname}, $rt)") or do {
                        diag $err;
                        next TEST;
                    };
                }
                push @js_code, "var $fn\_$rt = $code;\n\n";
            } # rt
        }

        push @js_code,
            "subtest(".$json->encode($tname).", function() {\n";

        # bool
        if ($test->{valid_inputs}) {
            # test multiple inputs, currently done for rt=bool only
            for my $i (0..@{ $test->{valid_inputs} }-1) {
                my $data = $test->{valid_inputs}[$i];
                push @js_code,
                    "    ok($fn\_bool(".$json->encode($data).")".
                        ", 'valid input [$i]');\n";
            }
            for my $i (0..@{ $test->{invalid_inputs} }-1) {
                my $data = $test->{invalid_inputs}[$i];
                push @js_code,
                    "    ok(!$fn\_bool(".$json->encode($data).")".
                        ", 'invalid input [$i]');\n";
            }
        } elsif (exists $test->{valid}) {
            if ($test->{valid}) {
                # XXX test output
                push @js_code,
                    "    ok($fn\_bool(".$json->encode($test->{input}).")".
                        ", 'valid (rt=bool)');\n";
            } else {
                push @js_code,
                    "    ok(!$fn\_bool(".$json->encode($test->{input}).")".
                        ", 'invalid (rt=bool)');\n";
            }
        }

        # str
        if (exists $test->{valid}) {
            if ($test->{valid}) {
                push @js_code,
                    "    ok($fn\_str(".$json->encode($test->{input}).")".
                        "=='', 'valid (rt=str)');\n";
            } else {
                push @js_code,
                    "    ok($fn\_str(".$json->encode($test->{input}).")".
                        ".match(/\\S/), 'invalid (rt=str)');\n";
            }
        }

        # full
        if (exists($test->{errors}) || exists($test->{warnings}) ||
                exists($test->{valid})) {
            my $errors   = $test->{errors} // ($test->{valid} ? 0 : 1);
            my $warnings = $test->{warnings} // 0;
            push @js_code, (
                "    res = $fn\_full(".$json->encode($test->{input}).");\n",
                "    ok(typeof(res)=='object', ".
                    "'validator (rt=full) returns object');\n",
                "    ok(Object.keys(res['errors']   ? res['errors']   : {}).length==$errors, 'errors (rt=full)');\n",
                "    ok(Object.keys(res['warnings'] ? res['warnings'] : {}).length==$warnings, ".
                    "'warnings (rt=full)');\n",
            );
        }

        push @js_code, "});\n\n";
    } # test

    push @js_code, <<'_';
done_testing();
process.exit(code = tap_num_nok == 0 ? 0:1);
_

    my ($jsh, $jsfn) = tempfile();
    note "js filename $jsfn";
    print $jsh @js_code;

    # finally we execute the js file, which should produce TAP
    my ($status, $errno);
    my ($merged, @result) = tee_merged {
        system($node_path, $jsfn);
        ($status, $errno) = ($?, $!);
    };
    # when node fails, we want to know the actual output
    ok(!$status, "js file executed successfully")
        or diag "output=<<$merged>>, exit status (\$?)=$status, ".
            "errno (\$!)=$errno, result=", explain(@result);
}

sub run_st_test_perl {
    my ($test) = @_;

    my $data = $test->{input};
    my $ho = exists($test->{output}); # has output
    my $vbool;
    eval { $vbool = $sah->gen_validator(
        $test->{schema}, {accept_ref=>$ho}) };
    my $eval_err = $@;
    if ($test->{dies}) {
        ok($eval_err, "compile error");
        return;
    } else {
        ok(!$eval_err, "compile success") or do {
            diag $eval_err;
            return;
        };
    }

    if ($test->{valid_inputs}) {
        # test multiple inputs, currently only done for rt=bool
        for my $i (0..@{ $test->{valid_inputs} }-1) {
            my $data = $test->{valid_inputs}[$i];
            ok($vbool->($ho ? \$data : $data), "valid input [$i]");
        }
        for my $i (0..@{ $test->{invalid_inputs} }-1) {
            my $data = $test->{invalid_inputs}[$i];
            ok(!$vbool->($ho ? \$data : $data), "invalid input [$i]");
        }
    } elsif (exists $test->{valid}) {
        # test a single input
        if ($test->{valid}) {
            ok($vbool->($ho ? \$data : $data), "valid (rt=bool)");
            if ($ho) {
                is_deeply($data, $test->{output}, "output");
            }
        } else {
            ok(!$vbool->($ho ? \$data : $data), "invalid (rt=bool)");
        }
    }

    my $vstr = $sah->gen_validator($test->{schema},
                                   {return_type=>'str'});
    if (exists $test->{valid}) {
        if ($test->{valid}) {
            is($vstr->($test->{input}), "", "valid (rt=str)");
        } else {
            like($vstr->($test->{input}), qr/\S/, "invalid (rt=str)");
        }
    }

    my $vfull = $sah->gen_validator($test->{schema},
                                    {return_type=>'full'});
    my $res = $vfull->($test->{input});
    is(ref($res), 'HASH', "validator (rt=full) returns hash");
    if (exists($test->{errors}) || exists($test->{warnings}) ||
            exists($test->{valid})) {
        my $errors = $test->{errors} // ($test->{valid} ? 0 : 1);
        is(scalar(keys %{ $res->{errors} // {} }), $errors, "errors (rt=full)")
            or diag explain $res;
        my $warnings = $test->{warnings} // 0;
        is(scalar(keys %{ $res->{warnings} // {} }), $warnings,
           "warnings (rt=full)")
            or diag explain $res;
    }
}

sub run_st_test_human {
    my ($test) = @_;

    # for human, we just check that compile doesn't die

    # XXX also check missing translation for languages?

    my $hc  = $sah->get_compiler('human');
    my $res;
    lives_ok {
        $res = $hc->compile(schema => $test->{schema}, locale=>'C');
    } "doesn't die";
}

sub test_human {
    my %args = @_;
    subtest $args{name} // $args{result}, sub {
        my $hc = $sah->get_compiler("human");
        my %hargs = (
            schema => $args{schema},
            lang => $args{lang},
            %{ $args{compile_opts} // {} },
        );
        $hargs{format} //= "inline_text";
        my $cd = $hc->compile(%hargs);

        if (defined $args{result}) {
            if (ref($args{result}) eq 'Regexp') {
                like($cd->{result}, $args{result}, 'result');
            } else {
                is($cd->{result}, $args{result}, 'result');
            }
        }
    };
}

1;
