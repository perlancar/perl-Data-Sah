package Data::Sah::Compiler::perl::TH::hash;

use 5.010;
use Log::Any '$log';
use Moo;
use experimental 'smartmatch';
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::hash';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'HASH'";
}

my $FRZ = "Storable::freeze";

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # Storable is chosen because it's core and fast. ~~ is not very
    # specific.
    $c->add_module($cd, 'Storable');

    if ($which eq 'is') {
        $c->add_ccl($cd, "$FRZ($dt) eq $FRZ($ct)");
    } elsif ($which eq 'in') {
        $c->add_smartmatch_pragma($cd);
        $c->add_ccl($cd, "$FRZ($dt) ~~ [map {$FRZ(\$_)} \@{ $ct }]");
    }
}

sub superclause_has_elems {
    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($which eq 'len') {
        $c->add_ccl($cd, "keys(\%{$dt}) == $ct");
    } elsif ($which eq 'min_len') {
        $c->add_ccl($cd, "keys(\%{$dt}) >= $ct");
    } elsif ($which eq 'max_len') {
        $c->add_ccl($cd, "keys(\%{$dt}) <= $ct");
    } elsif ($which eq 'len_between') {
        if ($cd->{cl_is_expr}) {
            $c->add_ccl(
                $cd, "keys(\%{$dt}) >= $ct\->[0] && ".
                    "keys(\%{$dt}) >= $ct\->[1]");
        } else {
            # simplify code
            $c->add_ccl(
                $cd, "keys(\%{$dt}) >= $cv->[0] && ".
                    "keys(\%{$dt}) <= $cv->[1]");
        }
    } elsif ($which eq 'has') {
        $c->add_smartmatch_pragma($cd);
        #$c->add_ccl($cd, "$FRZ($ct) ~~ [map {$FRZ(\$_)} values \%{ $dt }]");

        # XXX currently we choose below for speed, but only works for hash of
        # scalars. stringifying is required because smartmatch will switch to
        # numeric if we feed something like {a=>1}
        $c->add_ccl($cd, "$ct ~~ [values \%{ $dt }]");
    } elsif ($which eq 'each_index' || $which eq 'each_elem') {
        $self_th->gen_each($which, $cd, "keys(\%{$dt})",
                           "values(\%{$dt})");
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

sub clause_keys {
    my ($self_th, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;
    my $use_dpath = $cd->{args}{return_type} ne 'bool';

    # we handle subdata manually here, because in generated code for
    # keys.restrict, we haven't delved into the keys

    my $jccl;
    {
        local $cd->{ccls} = [];

        if ($cd->{clset}{"keys.restrict"} // 1) {
            local $cd->{_debug_ccl_note} = "keys.restrict";
            $c->add_module($cd, "List::Util");
            $c->add_smartmatch_pragma($cd);
            $c->add_ccl(
                $cd,
                "!defined(List::Util::first(sub {!(\$_ ~~ ".
                    $c->literal([keys %$cv]).")}, keys %{$dt}))",
                {
                    err_msg => 'TMP1',
                    err_expr => join(
                        "",
                        'sprintf(',
                        $c->literal($c->_xlt(
                            $cd, "hash contains ".
                                "unknown field(s) (%s)")),
                        ',',
                        'join(", ", sort grep {!($_~~[keys %{',
                        $c->literal($cv), "}])} keys %{$dt})",
                        ')',
                    ),
                },
            );
        }
        delete $cd->{uclset}{"keys.restrict"};

        my $cdef = $cd->{clset}{"keys.create_default"} // 1;
        delete $cd->{uclset}{"keys.create_default"};

        #local $cd->{args}{return_type} = 'bool';
        my $nkeys = scalar(keys %$cv);
        my $i = 0;
        for my $k (keys %$cv) {
            local $cd->{spath} = [@{ $cd->{spath} }, $k];
            ++$i;
            my $sch = $c->main->normalize_schema($cv->{$k});
            my $kdn = $k; $kdn =~ s/\W+/_/g;
            my $kdt = "$dt\->{".$c->literal($k)."}";
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

            # stack is used to store (non-bool) subresults
            $c->add_var($cd, '_sahv_stack', []) if $use_dpath;

            my @code = (
                ($c->indent_str($cd), "(push(@\$_sahv_dpath, undef), push(\@\$_sahv_stack, undef), \$_sahv_stack->[-1] = \n")
                    x !!($use_dpath && $i == 1),

                $sdef ? "" : "!exists($kdt) || (",

                ($c->indent_str($cd), "(\$_sahv_dpath->[-1] = ".
                     $c->literal($k)."),\n") x !!$use_dpath,
                $icd->{result}, "\n",

                $sdef ? "" : ")",

                ($c->indent_str($cd), "), (pop \@\$_sahv_dpath), pop(\@\$_sahv_stack)\n")
                    x !!($use_dpath && $i == $nkeys),
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "key: ".$c->literal($k);
            $c->add_ccl($cd, $ires);
        }
        $jccl = $c->join_ccls(
            $cd, $cd->{ccls}, {err_msg => ''});
    }
    $c->add_ccl($cd, $jccl, {});
}

sub clause_re_keys {
    my ($self, $cd) = @_;
    $self->compiler->_die_unimplemented_clause($cd);
}

sub clause_req_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_debug_ccl_note} = "req_keys";

    $c->add_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "!defined(List::Util::first(sub {!exists($dt\->{\$_})}, \@{".$c->literal($cv)."}))",
      {
        err_msg => 'TMP',
        err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash has missing required field(s) (%s)")).
          ",join(\", \", grep { !exists($dt\->{\$_}) } \@{".$c->literal($cv)."}))"
      }
    );
}

sub clause_allowed_keys {
    my ($self, $cd) = @_;
    $self->compiler->_die_unimplemented_clause($cd);
}

sub clause_allowed_keys_re {
    my ($self, $cd) = @_;
    $self->compiler->_die_unimplemented_clause($cd);
}

sub clause_forbidden_keys {
    my ($self, $cd) = @_;
    $self->compiler->_die_unimplemented_clause($cd);
}

sub clause_forbidden_keys_re {
    my ($self, $cd) = @_;
    $self->compiler->_die_unimplemented_clause($cd);
}

1;
# ABSTRACT: perl's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
