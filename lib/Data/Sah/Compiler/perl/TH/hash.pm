package Data::Sah::Compiler::perl::TH::hash;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Dmp;

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::hash';

# AUTHORITY
# DATE
# DIST
# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'HASH'";
}

sub superclause_comparable {
    my ($self, $which, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_runtime_module($cd, $cd->{args}{dump_module});

    if ($which eq 'is') {
        $c->add_ccl($cd, $c->expr_dump($cd, $dt).' eq '.$c->expr_dump($cd, $ct));
    } elsif ($which eq 'in') {
        $c->add_ccl($cd, "do { my \$_sahv_dt_str = ".$c->expr_dump($cd, $dt)."; my \$_sahv_res = 0; " .
                        "for my \$_sahv_el (\@{ $ct }) { my \$_sahv_el_str = ".$c->expr_dump($cd, "\$_sahv_el")."; ".
                        "if (\$_sahv_dt_str eq \$_sahv_el_str) { \$_sahv_res = 1; last } } \$_sahv_res }");
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
        $c->add_runtime_module($cd, $cd->{args}{dump_module});
        $c->add_ccl($cd, "do { my \$_sahv_ct_str = ".$c->expr_dump($cd, $ct)."; my \$_sahv_res = 0; " .
                        "for my \$_sahv_el (values \%{ $dt }) { my \$_sahv_el_str = ".$c->expr_dump($cd, "\$_sahv_el")."; ".
                        "if (\$_sahv_ct_str eq \$_sahv_el_str) { \$_sahv_res = 1; last } } \$_sahv_res }");
    } elsif ($which eq 'each_index') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "sort keys(\%{$cd->{data_term}})", '', '$_');
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
    } elsif ($which eq 'each_elem') {
        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        $self_th->gen_each($cd, "sort keys(\%{$cd->{data_term}})", '_', "$cd->{data_term}\->{\$_}");
        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
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
    require Data::Sah::Normalize;

    my ($self_th, $which, $cd) = @_;
    my $c  = $self_th->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    local $cd->{_subdata_level} = $cd->{_subdata_level} + 1;

    # we handle subdata manually here, because in generated code for
    # {keys,re_keys}.restrict, we haven't delved into the keys

    my $jccl;
    {
        local $cd->{ccls} = [];

        my $lit_valid_keys;
        if ($which eq 'keys') {
            $lit_valid_keys = $c->literal([sort keys %$cv]);
        } else {
            $lit_valid_keys = "[".
                join(",", map { "qr/".$c->_str2reliteral($cd, $_)."/" }
                         sort keys %$cv)."]";
        }

        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};

        if ($cd->{clset}{"$which.restrict"} // 1) {
            local $cd->{_debug_ccl_note} = "$which.restrict";
            #$c->add_runtime_module($cd, "List::Util");
            $c->add_ccl(
                $cd,
                #"!defined(List::Util::first(sub { my \$ditem=\$_; !defined(List::Util::first(sub {\$ditem ".($which eq 'keys' ? 'eq' : '=~')." \$_ }, \@{ $lit_valid_keys })) }, keys %{ $dt }))",
                "!(grep { my \$_sahv_dt_item=\$_; !(grep { \$_sahv_dt_item ".($which eq 'keys' ? 'eq' : '=~')." \$_ } \@{ $lit_valid_keys }) } keys %{ $dt })",
                {
                    err_msg => 'TMP',
                    err_expr => join(
                        "",
                        'sprintf(',
                        $c->literal($c->_xlt(
                            $cd, "hash contains ".
                                "unknown field(s) (%s)")),
                        ',',
                        "join(', ', sort grep { my \$_sahv_dt_item=\$_; !(grep { \$_sahv_dt_item ".($which eq 'keys' ? 'eq':'=~')." \$_ } \@{ $lit_valid_keys })} keys %{ $dt })",
                        ')',
                    ),
                },
            );
            $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};
        }
        delete $cd->{uclset}{"$which.restrict"};

        my $cdef;
        if ($which eq 'keys') {
            $cdef = $cd->{clset}{"keys.create_default"} // 1;
            delete $cd->{uclset}{"keys.create_default"};
        }

        $self_th->set_tmp_data_term($cd) if $cd->{args}{data_term_includes_topic_var};

        my $nkeys = scalar(keys %$cv);
        my $i = 0;
        for my $k (sort keys %$cv) {
            my $kre = $c->_str2reliteral($cd, $k);
            local $cd->{spath} = [@{ $cd->{spath} }, $k];
            ++$i;
            my $nsch = Data::Sah::Normalize::normalize_schema($cv->{$k});
            my $kdn = $k; $kdn =~ s/\W+/_/g;
            my $klit = $which eq 're_keys' ? '$_' : $c->literal($k);
            my $kdt = "$dt\->{$klit}";
            my %iargs = %{$cd->{args}};
            $iargs{outer_cd}             = $cd;
            $iargs{data_name}            = $kdn;
            $iargs{data_term}            = $kdt;
            $iargs{schema}               = $nsch;
            $iargs{schema_is_normalized} = 1;
            $iargs{cache}                = $cd->{args}{cache};
            $iargs{indent_level}++;
            $iargs{data_term_includes_topic_var} = 1 if $which eq 're_keys';
            my $icd = $c->compile(%iargs);

            # should we set default for hash value?
            my $sdef = $cdef && defined($nsch->[1]{default});

            # stack is used to store (non-bool) subresults
            $c->add_var($cd, '_sahv_stack', []) if $cd->{use_dpath};

            $c->add_runtime_module($cd, "List::Util") if $which eq 're_keys'; # for re_keys

            my @code = (
                ($c->indent_str($cd), "(push(@\$_sahv_dpath, undef), push(\@\$_sahv_stack, undef), \$_sahv_stack->[-1] = \n")
                    x !!($cd->{use_dpath} && $i == 1),

                # for re_keys, we iterate over all data's keys which match regex
                ('(!defined(List::Util::first(sub {!(')
                    x !!($which eq 're_keys'),

                $which eq 're_keys' ? "\$_ !~ /$kre/ || (" :
                    ($sdef ? "" : "!exists($kdt) || ("),

                ($c->indent_str($cd), "(\$_sahv_dpath->[-1] = ".
                     ($which eq 're_keys' ? '$_' : $klit)."),\n")
                         x !!$cd->{use_dpath},
                $icd->{result}, "\n",

                $which eq 're_keys' || !$sdef ? ")" : "",

                # close iteration over all data's keys which match regex
                (")}, sort keys %{ $dt })))")
                    x !!($which eq 're_keys'),

                ($c->indent_str($cd), "), pop(\@\$_sahv_dpath), pop(\@\$_sahv_stack)\n")
                    x !!($cd->{use_dpath} && $i == $nkeys),
            );
            my $ires = join("", @code);
            local $cd->{_debug_ccl_note} = "$which: ".$c->literal($k);
            $c->add_ccl($cd, $ires);
        }

        $self_th->restore_data_term($cd) if $cd->{args}{data_term_includes_topic_var};

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

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; !defined(List::Util::first(sub {!exists(\$_sahv_h\->{\$_})}, \@{ $ct })) }",
      {
        err_msg => 'TMP',
        err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash has missing required field(s) (%s)")).
          ",join(', ', do { my \$_sahv_h = $dt; grep { !exists(\$_sahv_h\->{\$_}) } \@{ $ct } }))"
      }
    );
}

sub clause_allowed_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    #$c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      #"!defined(List::Util::first(sub { my \$_sahv_dt_item=\$_; !defined(List::Util::first!(sub { \$_sahv_dt_item eq \$_ }, \@{ $ct })) }, keys \%{ $dt }))",
      "!(grep { my \$_sahv_dt_item=\$_; !(grep { \$_sahv_dt_item eq \$_ } \@{ $ct }) } keys \%{ $dt })",
      {
        err_msg => 'TMP',
        err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash contains non-allowed field(s) (%s)")).
          ",join(', ', sort grep { my \$_sahv_dt_item=\$_; !(grep { \$_sahv_dt_item eq \$_ } \@{ $ct }) } keys \%{ $dt }))"
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
    #$c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
        $cd,
        #"!defined(List::Util::first(sub {\$_ !~ /$re/}, keys \%{ $dt }))",
        "!(grep {\$_ !~ /$re/} keys \%{ $dt })",
        {
          err_msg => 'TMP',
          err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash contains non-allowed field(s) (%s)")).
          ",join(', ', sort grep { \$_ !~ /$re/ } keys \%{ $dt }))"
      }
    );
}

sub clause_forbidden_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    #$c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "!(grep { my \$_sahv_dt_item=\$_; !!(grep { \$_sahv_dt_item eq \$_ } \@{ $ct }) } keys \%{ $dt })",
      {
        err_msg => 'TMP',
        err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash contains forbidden field(s) (%s)")).
          ",join(', ', sort grep { my \$_sahv_dt_item=\$_; !(grep { \$_sahv_dt_item eq \$_ } \@{ $ct }) } keys \%{ $dt }))"
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
    #$c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
        $cd,
        #"!defined(List::Util::first(sub {\$_ =~ /$re/}, keys \%{ $dt }))",
        "!(grep {\$_ =~ /$re/} keys \%{ $dt })",
        {
          err_msg => 'TMP',
          err_expr =>
          "sprintf(".
          $c->literal($c->_xlt($cd, "hash contains forbidden field(s) (%s)")).
          ",join(', ', sort grep { \$_ =~ /$re/ } keys \%{ $dt }))"
      }
    );
}

sub clause_choose_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ $ct }) <= 1 }",
      {},
    );
}

sub clause_choose_all_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_keys = $ct; my \$_sahv_tot = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@\$_sahv_keys); \$_sahv_tot==0 || \$_sahv_tot==\@\$_sahv_keys }",
      {},
    );
}

sub clause_req_one_key {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ $ct }) == 1 }",
      {},
    );
}

sub clause_req_some_keys {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_n = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ ".$c->literal($cv->[2])." }); \$_sahv_n >= $cv->[0] && \$_sahv_n <= $cv->[1] }",
      {},
    );
}

sub clause_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_ct = $ct; ".
          "my \$_sahv_has_prereq = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ \$_sahv_ct->[1] }) ? 1:0; ".
          "my \$_sahv_has_dep    = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} (ref(\$_sahv_ct->[0]) eq 'ARRAY' ? \@{ \$_sahv_ct->[0] } : (\$_sahv_ct->[0]))) ? 1:0; ".
          "!\$_sahv_has_dep || \$_sahv_has_prereq }",
      {},
    );
}

sub clause_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_ct = $ct; ".
          "my \$_sahv_has_prereq = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ \$_sahv_ct->[1] }) == \@{ \$_sahv_ct->[1] } ? 1:0; ".
          "my \$_sahv_has_dep    = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} (ref(\$_sahv_ct->[0]) eq 'ARRAY' ? \@{ \$_sahv_ct->[0] } : (\$_sahv_ct->[0]))) ? 1:0; ".
          "!\$_sahv_has_dep || \$_sahv_has_prereq }",
      {},
    );
}

sub clause_req_dep_any {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_ct = $ct; ".
          "my \$_sahv_has_prereq = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ \$_sahv_ct->[1] }) ? 1:0; ".
          "my \$_sahv_has_dep    = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} (ref(\$_sahv_ct->[0]) eq 'ARRAY' ? \@{ \$_sahv_ct->[0] } : (\$_sahv_ct->[0]))) ? 1:0; ".
          "\$_sahv_has_dep || !\$_sahv_has_prereq }",
      {},
    );
}

sub clause_req_dep_all {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    # we assign to $_sahv_h first to avoid variable clashing if $dt is '$_'.

    $c->add_runtime_module($cd, "List::Util");
    $c->add_ccl(
      $cd,
      "do { my \$_sahv_h = $dt; my \$_sahv_ct = $ct; ".
          "my \$_sahv_has_prereq = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} \@{ \$_sahv_ct->[1] }) == \@{ \$_sahv_ct->[1] } ? 1:0; ".
          "my \$_sahv_has_dep    = List::Util::sum(map {exists(\$_sahv_h\->{\$_}) ? 1:0} (ref(\$_sahv_ct->[0]) eq 'ARRAY' ? \@{ \$_sahv_ct->[0] } : (\$_sahv_ct->[0]))) ? 1:0; ".
          "\$_sahv_has_dep || !\$_sahv_has_prereq }",
      {},
    );
}

1;
# ABSTRACT: perl's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
