package Data::Sah::Compiler::js::TH::hash;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::hash';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    # XXX also exclude RegExp, ...
    $cd->{_ccl_check_type} = "typeof($dt)=='object' && !($dt instanceof Array)";
}

my $STR = "JSON.stringify";

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'is') {
        $c->add_ccl($cd, "$STR($dt) == $STR($ct)");
    } elsif ($which eq 'in') {
        $c->add_ccl(
            $cd,
            "!($ct).every(function(x){return $STR(x) != $STR($dt) })");
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # XXX need to optimize, Object.keys(h).length is not efficient

    if ($which eq 'len') {
        $c->add_ccl($cd, "Object.keys($dt).length == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "Object.keys($dt).length >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "Object.keys($dt).length <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "Object.keys($dt).length >= $ct\->[0] && ".
                    "Object.keys($dt).length >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "Object.keys($dt).length >= $cv->[0] && ".
                    "Object.keys($dt).length <= $cv->[1]");
        }
    } elsif ($which eq 'has') {
        $c->add_ccl(
            $cd,
            "!Object.keys($dt).every(function(x){return $STR(($dt)[x]) != $STR($ct) })");
    } elsif ($which eq 'each_index') {
        $self_th->gen_each($cd, "Object.keys($dt)", '_sahv_idx', '_sahv_idx');
    } elsif ($which eq 'each_elem') {
        $self_th->gen_each($cd, "Object.keys($dt)", '_sahv_idx', "$dt\[_sahv_idx]");
    } elsif ($which eq 'check_each_index') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'check_each_elem') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'uniq') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    } elsif ($which eq 'exists') {
        $self_th->compiler->_die_unimplemented_clause($cd);
    }
}

sub _clause_keys_or_re_keys {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    # we handle subdata manually here, because in generated code for
    # keys.restrict, we haven't delved into the keys

    my $jccl;
    {
        local $cd->{ccls} = [];

        my $chk_x_unknown;
        my $filt_x_unknown;
        if ($which eq 'keys') {
            my $lit_valid_keys = $c->literal([keys %$cv]);
            $chk_x_unknown  = "$lit_valid_keys.indexOf(x) > -1";
            $filt_x_unknown = "$lit_valid_keys.indexOf(x) == -1";
        } else {
            my $lit_regexes = "[".
                join(",", map { $c->_str2reliteral($cd, $_) }
                         keys %$cv)."]";
            $chk_x_unknown  = "!$lit_regexes.every(function(y) { return !x.match(y) })";
            $filt_x_unknown = "$lit_regexes.every(function(y) { return !x.match(y) })";
        }

        if ($cd->{clset}{"$which.restrict"} // 1) {
            local $cd->{_debug_ccl_note} = "$which.restrict";
            $c->add_ccl(
                $cd,
                "Object.keys($dt).every(function(x){ return $chk_x_unknown })",
                {
                    err_msg => 'TMP1',
                    err_expr => join(
                        "",
                        $c->literal($c->_xlt(
                            $cd, "hash contains ".
                                "unknown field(s) (%s)")),
                        '.replace("%s", ',
                        "Object.keys($dt).filter(function(x){ return $filt_x_unknown }).join(', ')",
                        ')',
                    ),
                },
            );
        }
        delete $cd->{uclset}{"$which.restrict"};

        my $cdef;
        if ($which eq 'keys') {
            $cdef = $cd->{clset}{"keys.create_default"} // 1;
            delete $cd->{uclset}{"keys.create_default"};
        }

        my $nkeys = scalar(keys %$cv);
        my $i = 0;
        for my $k (sort keys %$cv) {
            my $kre = $c->_str2reliteral($cd, $k);
            local $cd->{spath} = [@{ $cd->{spath} }, $k];
            ++$i;
            my $sch = $c->main->normalize_schema($cv->{$k});
            my $kdn = $k; $kdn =~ s/\W+/_/g;
            my $klit = $which eq 're_keys' ? 'x' : $c->literal($k);
            my $kdt = "$dt\[$klit]";
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{data_name}            = $kdn;
            $iargs{data_term}            = $kdt;
            $iargs{schema}               = $sch;
            $iargs{schema_is_normalized} = 1;
            $iargs{indent_level}++;
            my $icd = $c->compile(%iargs);

            # should we set default for hash value?
            my $sdef = $cdef && defined($sch->[1]{default});

            $c->add_var($cd, '_sahv_stack', []) if $cd->{use_dpath};

            my @code = (
                ($c->indent_str($cd), "(_sahv_dpath.push(null), _sahv_stack.push(null), _sahv_stack[_sahv_stack.length-1] = \n")
                    x !!($cd->{use_dpath} && $i == 1),

                # for re_keys, we iterate over all data's keys which match regex
                ("Object.keys($dt).every(function(x) { return (")
                    x !!($which eq 're_keys'),

                $which eq 're_keys' ? "!x.match($kre) || (" :
                    ($sdef ? "" : "!$dt.hasOwnProperty($klit) || ("),

                ($c->indent_str($cd), "(_sahv_dpath[_sahv_dpath.length-1] = ".
                     ($which eq 're_keys' ? 'x' : $klit)."),\n") x !!$cd->{use_dpath},
                $icd->{result}, "\n",

                $which eq 're_keys' || !$sdef ? ")" : "",

                # close iteration over all data's keys which match regex
                (") })")
                    x !!($which eq 're_keys'),

                ($c->indent_str($cd), "), _sahv_dpath.pop(), _sahv_stack.pop()\n")
                    x !!($cd->{use_dpath} && $i == $nkeys),
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "$which: ".$c->literal($k);
            $c->add_ccl($cd, $ires);
        }
        $jccl = $c->join_ccls(
            $cd, $cd->{ccls}, {err_msg => ''});
    }
    $c->add_ccl($cd, $jccl, {});
}

sub clause_keys {
    my ($self, $cd) = @_;
    $self->_clause_keys_or_re_keys('keys', $cd);
}

sub clause_re_keys {
    my ($self, $cd) = @_;
    $self->_clause_keys_or_re_keys('re_keys', $cd);
}

sub clause_req_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
      $cd,
      "($ct).every(function(x){ return Object.keys($dt).indexOf(x) > -1 })", # XXX cache Object.keys($dt)
      {
        err_msg => 'TMP',
        err_expr => join(
            "",
            $c->literal($c->_xlt(
                $cd, "hash has missing required field(s) (%s)")),
            '.replace("%s", ',
            "($ct).filter(function(x){ return Object.keys($dt).indexOf(x) == -1 }).join(', ')",
            ')',
        ),
      }
    );
}

sub clause_allowed_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
      $cd,
      "Object.keys($dt).every(function(x){ return ($ct).indexOf(x) > -1 })", # XXX cache Object.keys($ct)
      {
        err_msg => 'TMP',
        err_expr => join(
            "",
            $c->literal($c->_xlt(
                $cd, "hash contains non-allowed field(s) (%s)")),
            '.replace("%s", ',
            "Object.keys($dt).filter(function(x){ return ($ct).indexOf(x) == -1 }).join(', ')",
            ')',
        ),
      }
    );
}

sub clause_allowed_keys_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    #my $ct = $cd->{cl_term};
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy atm and does not need expr yet
        $c->_die_unimplemented_clause($cd, "with expr");
    }

    my $re = $c->_str2reliteral($cd, $cv);
    $c->add_ccl(
      $cd,
      "Object.keys($dt).every(function(x){ return x.match(RegExp($re)) })",
      {
        err_msg => 'TMP',
        err_expr => join(
            "",
            $c->literal($c->_xlt(
                $cd, "hash contains non-allowed field(s) (%s)")),
            '.replace("%s", ',
            "Object.keys($dt).filter(function(x){ return !x.match(RegExp($re)) }).join(', ')",
            ')',
        ),
      }
    );
}

sub clause_forbidden_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
      $cd,
      "Object.keys($dt).every(function(x){ return ($ct).indexOf(x) == -1 })", # XXX cache Object.keys($ct)
      {
        err_msg => 'TMP',
        err_expr => join(
            "",
            $c->literal($c->_xlt(
                $cd, "hash contains forbidden field(s) (%s)")),
            '.replace("%s", ',
            "Object.keys($dt).filter(function(x){ return ($ct).indexOf(x) > -1 }).join(', ')",
            ')',
        ),
      }
    );
}

sub clause_forbidden_keys_re {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    #my $ct = $cd->{cl_term};
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        # i'm lazy atm and does not need expr yet
        $c->_die_unimplemented_clause($cd, "with expr");
    }

    my $re = $c->_str2reliteral($cd, $cv);
    $c->add_ccl(
      $cd,
      "Object.keys($dt).every(function(x){ return !x.match(RegExp($re)) })",
      {
        err_msg => 'TMP',
        err_expr => join(
            "",
            $c->literal($c->_xlt(
                $cd, "hash contains forbidden field(s) (%s)")),
            '.replace("%s", ',
            "Object.keys($dt).filter(function(x){ return x.match(RegExp($re)) }).join(', ')",
            ')',
        ),
      }
    );
}

sub clause_choose_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "($ct).map(function(x) {",
            "  return ($dt).hasOwnProperty(x) ? 1:0",
            "}).reduce(function(a,b){ return a+b }) <= 1",
        ),
        {},
    );
}

sub clause_choose_all_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "[0, ($ct).length].indexOf(",
            "  ($ct).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b })",
            ") >= 0",
        ),
        {},
    );
}

sub clause_req_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "($ct).map(function(x) {",
            "  return ($dt).hasOwnProperty(x) ? 1:0",
            "}).reduce(function(a,b){ return a+b }) == 1",
        ),
        {},
    );
}

sub clause_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "(function(_sahv_ct, _sahv_has_prereq, _sahv_has_dep) {", # a trick to have lexical variable like 'let', 'let' is only supported in js >= 1.7 (ES6)
            "  _sahv_ct = $ct; ",
            "  _sahv_has_prereq = (_sahv_ct[1]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  _sahv_has_dep    = (_sahv_ct[0].constructor===Array ? _sahv_ct[0] : [_sahv_ct[0]]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  return !_sahv_has_dep || _sahv_has_prereq",
            "})()",
        ),
        {},
    );
}

sub clause_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "(function(_sahv_ct, _sahv_has_prereq, _sahv_has_dep) {", # a trick to have lexical variable like 'let', 'let' is only supported in js >= 1.7 (ES6)
            "  _sahv_ct = $ct; ",
            "  _sahv_has_prereq = (_sahv_ct[1]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) == _sahv_ct[1].length; ",
            "  _sahv_has_dep    = (_sahv_ct[0].constructor===Array ? _sahv_ct[0] : [_sahv_ct[0]]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  return !_sahv_has_dep || _sahv_has_prereq",
            "})()",
        ),
        {},
    );
}

sub clause_req_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "(function(_sahv_ct, _sahv_has_prereq, _sahv_has_dep) {", # a trick to have lexical variable like 'let', 'let' is only supported in js >= 1.7 (ES6)
            "  _sahv_ct = $ct; ",
            "  _sahv_has_prereq = (_sahv_ct[1]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  _sahv_has_dep    = (_sahv_ct[0].constructor===Array ? _sahv_ct[0] : [_sahv_ct[0]]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  return _sahv_has_dep || !_sahv_has_prereq",
            "})()",
        ),
        {},
    );
}

sub clause_req_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl(
        $cd,
        join(
            "",
            "(function(_sahv_ct, _sahv_has_prereq, _sahv_has_dep) {", # a trick to have lexical variable like 'let', 'let' is only supported in js >= 1.7 (ES6)
            "  _sahv_ct = $ct; ",
            "  _sahv_has_prereq = (_sahv_ct[1]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) == _sahv_ct[1].length; ",
            "  _sahv_has_dep    = (_sahv_ct[0].constructor===Array ? _sahv_ct[0] : [_sahv_ct[0]]).map(function(x) {",
            "    return ($dt).hasOwnProperty(x) ? 1:0",
            "  }).reduce(function(a,b){ return a+b }) > 0; ",
            "  return _sahv_has_dep || !_sahv_has_prereq",
            "})()",
        ),
        {},
    );
}

1;
# ABSTRACT: js's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
