package Data::Sah::Compiler::perl;

use 5.010;
use Moo;
use Log::Any qw($log);
extends 'Data::Sah::Compiler::BaseProg';

# VERSION

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('shell');
    $self->indent_character(" " x 4);
    $self->var_sigil('$');
}

sub name { "perl" }

sub literal {
    require Data::Dumper;

    my ($self, $val) = @_;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    #local $Data::Dumper::Deepcopy = 1;
    my $res = Data::Dumper::Dumper($val);
    chomp $res;
    $res;
}

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->perl($expr);
}

sub load_module {
    my ($self, $name) = @_;
    my $namep = $name; $namep =~ s!::!/!g; $namep .= ".pm";
    require $namep;
}

sub compile {
    my ($self, %args) = @_;

    $self->expr_compiler->compiler->hook_var(
        sub {
            $_[0];
        }
    );
    #$self->expr_compiler->compiler->hook_func(
    #    sub {
    #        my ($name, @args) = @_;
    #        die "Unknown function $name"
    #            unless $self->main->func_names->{$name};
    #        my $subname = "func_$name";
    #        $self->define_sub_start($subname);
    #        my $meth = "func_$name";
    #        $self->func_handlers->{$name}->$meth;
    #        $self->define_sub_end();
    #        $subname . "(" . join(", ", @args) . ")";
    #    }
    #);

    $self->SUPER::compile(%args);
}

# add compiled clause to ccls, along with extra information useful for joining
# later (like error level, code for adding error message, etc). available
# options: err_level (str, the default will be taken from current clause's
# .err_level if not specified), err_msg (str, the default will be produced by
# human compiler if not supplied, or taken from current clause's
# .err_msg/.ok_err_msg)
sub add_ccl {
    my ($self, $cd, $ccl, $opts) = @_;
    $opts //= {};
    my $clause = $cd->{clause} // "";

    my $el = $opts->{err_level} // $cd->{cset}{"$clause.err_level"} // "error";
    my $err_msg    = $opts->{err_msg}    // $cd->{cset}{"$clause.err_msg"};
    my $ok_err_msg = $opts->{ok_err_msg} // $cd->{cset}{"$clause.ok_err_msg"};

    my ($err_expr, $ok_err_expr);
    unless (defined $err_msg) {
        # XXX generate from human compiler, e.g. $err_expr = '$h->compile(...)'
        $err_msg = "TMPERRMSG: clause failed: $clause";
    }
    unless (defined $ok_err_msg) {
        # XXX generate from human compiler, e.g. $err_expr = '$h->compile(...)'
        $ok_err_msg = "TMPERRMSG: clause succeed: $clause";
    }
    $err_expr    //= $self->literal($err_msg);
    $ok_err_expr //= $self->literal($ok_err_msg);

    my $vrt = $cd->{args}{validator_return_type};
    my $et  = $cd->{args}{err_term};
    my ($err_code, $ok_err_code);
    if ($vrt eq 'full') {
        my $k = $el eq 'warn' ? 'warnings' : 'errors';
        $err_code    = "push \@{ $et\->{$k} }, $err_expr";
        $ok_err_code = "push \@{ $et\->{$k} }, $ok_err_expr";
    } elsif ($vrt eq 'str' && $el ne 'warn') {
        $err_code    = "$et = $err_expr";
        $ok_err_code = "$et = $ok_err_expr";
    }

    push @{ $cd->{ccls} }, {
        ccl             => $ccl,
        err_level       => $el,
        err_code        => $err_code,
        ok_err_code     => $ok_err_code,
        (_debug_ccl_note => $cd->{_debug_ccl_note}) x !!$cd->{_debug_ccl_note},
    };
    delete $cd->{ucset}{"$clause.err_level"};
    delete $cd->{ucset}{"$clause.err_msg"};
    delete $cd->{ucset}{"$clause.ok_err_msg"};
}

# join ccls to handle {min,max}_{ok,nok} and insert error messages. opts =
# {min,max}_{ok,nok}, err_term (default from $cd->{args}{err_term})
sub join_ccls {
    my ($self, $cd, $ccls, $opts) = @_;
    $opts //= {};
    my $min_ok   = $opts->{min_ok};
    my $max_ok   = $opts->{max_ok};
    my $min_nok  = $opts->{min_nok};
    my $max_nok  = $opts->{max_nok};
    my $dmin_ok  = defined($opts->{min_ok});
    my $dmax_ok  = defined($opts->{max_ok});
    my $dmin_nok = defined($opts->{min_nok});
    my $dmax_nok = defined($opts->{max_nok});

    return "" unless @$ccls;

    # TODO: support expression for {min,max}_{ok,nok} attributes. to do this we
    # need to introduce scope so that (local $ok=0,$nok=0) can be nested.

    # default is AND
    $max_nok = 0 if !$dmin_ok && !$dmax_ok && !$dmin_nok && !$dmax_nok;

    my $vrt     = $cd->{args}{validator_return_type};
    my $ichar   = $self->indent_character;
    my $indent  = $ichar x $cd->{indent_level};
    my $indent2 = $ichar x ($cd->{indent_level}+1);

    # insert comment and error message. prevent/force shortcut. which=0|1 (for
    # inserting ok_err_code instead of err_code).
    state $_ice = sub {
        my ($ccl, $which) = @_;
        my $eck = $which ? "ok_err_code" : "err_code";
        my $ret = $ccl->{err_level} eq 'fatal' ? 0 :
            $vrt eq 'full' || $ccl->{err_level} eq 'warn' ? 1 : 0;
        my $res = $ccl->{_debug_ccl_note} ?
            "$indent# $ccl->{_debug_ccl_note}\n" : "";
        $res .= $indent;
        if ($vrt eq 'bool' && $ret) {
            $res .= "1";
        } elsif ($ccl->{err_level} eq 'none') {
            $res .= "(" . $self->enclose_paren($ccl->{ccl}) . ", 1)";
        } elsif ($vrt eq 'bool' || !$ccl->{err_code}) {
            $res .= $self->enclose_paren($ccl->{ccl});
        } else {
            $res .= "(" . $self->enclose_paren($ccl->{ccl}) .
                " ? 1 : (($ccl->{err_code}), $ret))";
        }
        $res .= "\n";
        $res;
    };

    if (@$ccls==1 &&
            !$dmin_ok && $dmax_ok && $max_ok==0 && !$dmin_nok && !$dmax_nok) {
        # special case for NOT
        local $ccls->[0]{ccl} = "!($ccls->[0]{ccl})";
        return $_ice->($ccls->[0], 1);
    } elsif (!$dmin_ok && !$dmax_ok && !$dmin_nok && (!$dmax_nok||$max_nok==0)){
        # special case for AND
        return join " &&\n", map { $_ice->($_) } @$ccls;
    } else {
        my @ee;
        for (my $i=0; $i<@$ccls; $i++) {
            my $e = "";
            if ($i == 0) {
                $e .= '(local $ok=0, $nok=0), ';
            }
            $e .= $self->enclose_paren($ccls->[$i][0]).' ? $ok++:$nok++';

            my @oee;
            push @oee, '$ok <= '. $max_ok  if $dmax_ok;
            push @oee, '$nok <= '.$max_nok if $dmax_nok;
            if ($i == @$ccls-1) {
                push @oee, '$ok >= '. $min_ok  if $dmin_ok;
                push @oee, '$nok >= '.$min_nok if $dmin_nok;
            }
            push @oee, '1' if !@oee;
            $e .= ", ".join("", @oee); # $j2

            push @ee, $e;
        }

        my $tmperrmsg;
        for ($tmperrmsg) {
            $_ = "TMPERRMSG: ";
            $_ .= $cd->{clause} ? "clause $cd->{clause}" : "cset";
            $_ .= " min_ok=$min_ok"   if $dmin_ok;
            $_ .= " max_ok=$max_ok"   if $dmax_ok;
            $_ .= " min_nok=$min_nok" if $dmin_nok;
            $_ .= " max_nok=$max_nok" if $dmax_nok;
        }

        return join "", map { $self->_insert_error_msg_to_expr( # $j
            $cd, $_, $tmperrmsg, $vrt) } @ee;
    }
}

sub before_clause_set {
    my ($self, $cd) = @_;

    $self->SUPER::before_clause_set($cd)
        if $self->can("SUPER::before_all_clause_set");

    my $dt    = $cd->{data_term};
    my $cset  = $cd->{cset};

    my $def = $cset->{default};
    if (defined $def) {
        my $ct = $cset->{"default.is_expr"} ?
            $self->expr($def) : $self->literal($def);
        $self->add_ccl(
            ccl => "($dt //= $ct)",
            err_level => 'none',
        );
    }

    # XXX insert prefilters

    my $req   = $cset->{req};
    my $reqie = $cset->{"req.is_expr"};
    my $req_err_msg = "TMPERRMSG: required data not specified";
    if ($req && !$reqie) {
        $self->add_ccl(
            ccl       => "defined($dt)",
            err_msg   => $req_err_msg,
            err_level => 'fatal',
        );
    } elseif ($reqie) {
        my $ct = $self->expr($req);
        $self->add_ccl(
            ccl       => "!($ct) || defined($dt)",
            err_msg   => $req_err_msg,
            err_level => 'fatal',
        );
    }

    my $fbd   = $cset->{forbidden};
    my $fbdie = $cset->{"forbidden.is_expr"};
    my $fbd_err_msg = "TMPERRMSG: forbidden data specified";
    if ($fbd && !$fbdie) {
        $self->add_ccl(
            ccl       => "!defined($dt)",
            err_msg   => $fbd_err_msg,
            err_level => 'fatal',
        );
    } elseif ($fbdie) {
        my $ct = $self->expr($fbd);
        $self->add_ccl(
            ccl       => "!($ct) || !defined($dt)",
            err_msg   => $fbd_err_msg,
            err_level => 'fatal',
        );
    }

    if ($cd->{cset_num} == 0) {
        $self->_die("BUG: handler did not produce _ccl_check_type")
            unless defined($cd->{_ccl_check_type});
        $self->add_ccl(
            ccl       => $cd->{_ccl_check_type},
            err_msg   => 'TMPERRMSG: type check failed',
            err_level => 'fatal',
        );
    }

    delete $cd->{ucset}{"default"};
    delete $cd->{ucset}{"default.is_expr"};
    delete $cd->{ucset}{"req"};
    delete $cd->{ucset}{"req.is_expr"};
    delete $cd->{ucset}{"forbidden"};
    delete $cd->{ucset}{"forbidden.is_expr"};
    #delete $cd->{ucset}{"prefilters"};
}

sub after_all_clauses {
    my ($self, $cd) = @_;


    if (delete $cd->{"perl._skip_undef"}) {
        my $jccl = $self->join_ccls(
            $cd,
            [splice(@{ $cd->{ccls} }, $cd->{_ccls_idx_cset})],
        );
        $cd->{ccls} = [];
        push @{ $cd->{ccls} }, {
            ccl => "!defined($cd->{data_term}) ?  1 : ".
                $self->enclose_paren($jccl),
            err_level => 'error',
        };
    }

    $self->SUPER::after_all_clauses($cd)
        if $self->can("SUPER::after_all_clauses");
}

1;
# ABSTRACT: Compile Sah schema to Perl code

=for Pod::Coverage BUILD

=head1 SYNOPSIS

 # see Data::Sah


=head1 DESCRIPTION


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from BaseProg's arguments, this class supports these arguments:

=over 4

=back

=cut
