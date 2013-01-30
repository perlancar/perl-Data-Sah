use 5.010;
use strict;
use warnings;
use FindBin qw($Bin);

use Data::Sah;
use File::chdir;
use File::ShareDir::Tarball;
use Test::Exception;
use Test::More 0.98;
use YAML::Syck qw(LoadFile);

$YAML::Syck::ImplicitTyping = 1;

my $sah = Data::Sah->new;

sub run_spectest {
    my ($cname, $opts) = @_; # compiler name
    $opts //= {};

    my $dir = File::ShareDir::Tarball::dist_dir("Sah");
    $dir && (-d $dir) or die "Can't find spectest, have you installed Sah?";
    (-f "$dir/spectest/00-normalize_schema.yaml")
        or die "Something's wrong, spectest doesn't contain the correct files";

    my @specfiles;
    {
        local $CWD = "$dir/spectest";
        @specfiles = <*.yaml>;
    }

    #my @files = split /\s+/, ($ENV{SAH_SPECTEST_FILES} // "");
    my @files = @ARGV;

    goto SKIP1 unless $cname eq 'perl';

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

  SKIP1:

    for my $file (grep /^10-type-/, @specfiles) {
        next unless !@files || $file ~~ @files;
        subtest $file => sub {
            diag "Loading $file ...";
            my $yaml = LoadFile("$dir/spectest/$file");
            note "Test version: ", $yaml->{version};
            my $tests = $yaml->{tests};
            if ($cname eq 'perl') {
                run_st_tests_perl($tests, $opts);
            } elsif ($cname eq 'human') {
                run_st_tests_human($tests, $opts);
            } elsif ($cname eq 'js') {
                run_st_tests_js($tests, $opts);
            }
        };
    } # file
}

sub run_st_tests_perl {
    my ($tests, $opts) = @_;
    for my $test (@$tests) {
        note explain $test;
        subtest $test->{name} => sub {
            run_st_test_perl($test);
        };
    }
}

sub run_st_tests_human {
    my ($tests, $opts) = @_;
    for my $test (@$tests) {
        note explain $test;
        subtest $test->{name} => sub {
            run_st_test_human($test);
        };
    }
}

sub run_st_tests_js {
    require JSON;

    my ($tests, $opts) = @_;

    # we're using node.js to execute javascript code. first we compile all the
    # schemas into functions (eliminating all duplicates) and put them in a node
    # module file, then call the node's executable (either called 'node', or
    # 'nodejs' in debian).

    my $node_path = $opts->{node_path} // get_nodejs_path();
    state $json = JSON->new->allow_nonref;
    my $js = $sah->get_compiler('js');

    my %validators; # key: json(schema)
    my %counters; # key: type name
    for my $test (@$tests) {
        my $k = $json->encode($test->{schema});
        my $ns = $sah->normalize_schema($test->{schema});
        $test->{nschema} = $ns;
        next if $validators{$k};
        $validators{$k} = {name => $ns->[0] . ++$counters{$ns->[0]}};
        for my $rt (qw/bool str full/) {
            $validators{$k}{"code_$rt"} = $js->expr_validator_sub(
                schema => $ns,
                schema_is_normalized => 1,
                return_type => $rt,
            );
        }
    }

    diag explain \%validators;
    #for my $test (@$tests) {
    #    note explain $test;
    #    subtest $test->{name} => sub {
    #        run_st_test_jshuman($test);
    #    };
    #}
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

    if ($test->{valid}) {
        ok($vbool->($ho ? \$data : $data), "valid (vrt=bool)");
        if ($ho) {
            is_deeply($data, $test->{output}, "output");
        }
    } else {
        ok(!$vbool->($ho ? \$data : $data), "invalid (vrt=bool)");
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
    is(scalar(keys %{ $res->{errors} // {} }), $errors, "errors (vrt=full)")
        or diag explain $res;
    my $warnings = $test->{warnings} // 0;
    is(scalar(keys %{ $res->{warnings} // {} }), $warnings,
       "warnings (vrt=full)")
        or diag explain $res;
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

# check availability of the node.js executable, return the path to executable or
# undef if none is available
sub get_nodejs_path {
    require File::Which;

    my $path;
    for my $name (qw/nodejs node/) {
        $path = File::Which::which($name);
        next unless $path;

        # check if it's really nodejs
        my $cmd = "$path -e 'console.log(1+1)'";
        my $out = `$cmd`;
        if ($out =~ /\A2\n?\z/) {
            note "node.js binary is $path";
            return $path;
        } else {
            note "Output of $cmd: $out";
        }
    }
    return undef;
}

1;
