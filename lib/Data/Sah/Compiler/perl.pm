package Data::Sah::Compiler::perl;

use 5.010;
use Moo;
use Log::Any qw($log);
extends 'Data::Sah::Compiler::Prog';

use SHARYANTO::String::Util;

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
    local $Data::Dumper::Useqq    = 1;
    my $res = Data::Dumper::Dumper($val);
    chomp $res;
    $res;
}

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->perl($expr);
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

    my $has_err    = !(defined($err_msg)    && $err_msg    eq '');
    my $has_ok_err = !(defined($ok_err_msg) && $ok_err_msg eq '');
    if (!defined($err_msg)) {
        # XXX generate from human compiler, e.g. $err_expr = '$h->compile(...)'
        $err_msg = "TMPERRMSG: clause failed: $clause";
    }
    if (!defined($ok_err_msg)) {
        # XXX generate from human compiler, e.g. $err_expr = '$h->compile(...)'
        $ok_err_msg = "TMPERRMSG: clause succeed: $clause";
    }
    my $err_expr    = $self->literal($err_msg)    if $has_err;
    my $ok_err_expr = $self->literal($ok_err_msg) if $has_ok_err;

    my $rt  = $cd->{args}{return_type};
    my $et  = $cd->{args}{err_term};
    my ($err_code, $ok_err_code);
    if ($rt eq 'full') {
        my $k = $el eq 'warn' ? 'warnings' : 'errors';
        $err_code    = "push \@{ $et\->{$k} }, $err_expr"    if $has_err;
        $ok_err_code = "push \@{ $et\->{$k} }, $ok_err_expr" if $has_ok_err;
    } elsif ($rt eq 'str') {
        if ($el eq 'warn') {
            $has_err = 0;
            $has_ok_err = 0;
        } else {
            $err_code    = "$et = $err_expr"    if $has_err;
            $ok_err_code = "$et = $ok_err_expr" if $has_ok_err;
        }
    }

    my $res = {
        ccl             => $ccl,
        err_level       => $el,
        has_err         => $has_err,
        has_ok_err      => $has_ok_err,
        err_code        => $err_code,
        ok_err_code     => $ok_err_code,
        (_debug_ccl_note => $cd->{_debug_ccl_note}) x !!$cd->{_debug_ccl_note},
    };
    push @{ $cd->{ccls} }, $res;
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

    # TODO: support expression for {min,max}_{ok,nok} attributes.

    # default is AND
    $max_nok = 0 if !$dmin_ok && !$dmax_ok && !$dmin_nok && !$dmax_nok;

    my $rt      = $cd->{args}{return_type};
    my $vp      = $cd->{args}{var_prefix};
    my $ichar   = $self->indent_character;
    my $indent  = $ichar x $cd->{indent_level};
    my $indent2 = $ichar x ($cd->{indent_level}+1);

    my $j  = "\n$indent  &&\n";
    my $j2 = "\n$indent2  &&\n";

    # insert comment, error message, and $ok/$nok counting. $which is 0 by
    # default (normal), or 1 (reverse logic, for NOT), or 2 (for $ok/$nok
    # counting), or 3 (like 2, but for the last clause).
    my $_ice = sub {
        my ($ccl, $which) = @_;

        my $res = "";

        if ($ccl->{_debug_ccl_note}) {
            if ($cd->{args}{debug_log_clause} || $cd->{args}{debug}) {
                $self->add_module($cd, 'Log::Any');
                $res .= "$indent(\$log->tracef('%s ...', ".
                    $self->literal($ccl->{_debug_ccl_note})."), 1) && \n";
            } else {
                $res .= $indent . $self->comment($cd, $ccl->{_debug_ccl_note});
            }
        }

        $res .= $indent;
        $which //= 0;
        my $e = ($which == 1 ? "!" : "") . $self->enclose_paren($ccl->{ccl});
        my ($ec, $oec);
        my ($ret, $oret);
        if ($which >= 2) {
            my @chk;
            if ($ccl->{err_level} eq 'warn') {
                $oret = 1;
                $ret  = 1;
            } elsif ($ccl->{err_level} eq 'fatal') {
                $oret = 1;
                $ret  = 0;
            } else {
                $oret = "++\$${vp}ok";
                $ret  = "++\$${vp}nok";
                push @chk, "\$${vp}ok <= $max_ok"   if $dmax_ok;
                push @chk, "\$${vp}nok <= $max_nok" if $dmax_nok;
                if ($which == 3) {
                    push @chk, "\$${vp}ok >= $min_ok"   if $dmin_ok;
                    push @chk, "\$${vp}nok >= $min_nok" if $dmin_nok;
                }
            }
            $res .= "($e ? $oret : $ret)";
            $res .= " && " . join(" && ", @chk) if @chk;
        } else {
            $ec = $ccl->{ $which == 1 ? "ok_err_code" : "err_code" };
            $ret = $ccl->{err_level} eq 'fatal' ? 0 :
                $rt eq 'full' || $ccl->{err_level} eq 'warn' ? 1 : 0;
            if ($rt eq 'bool' && $ret) {
                $res .= "1";
            } elsif ($rt eq 'bool' || !$ccl->{has_err}) {
                $res .= $self->enclose_paren($e);
            } else {
                $res .= $self->enclose_paren(
                    $self->enclose_paren($e) . " ? 1 : (($ec),$ret)",
                    "force");
            }
        }
        $res;
    };

    if (@$ccls==1 &&
            !$dmin_ok && $dmax_ok && $max_ok==0 && !$dmin_nok && !$dmax_nok) {
        # special case for NOT
        return $_ice->($ccls->[0], 1);
    } elsif (!$dmin_ok && !$dmax_ok && !$dmin_nok && (!$dmax_nok||$max_nok==0)){
        # special case for AND
        return join $j, map { $_ice->($_) } @$ccls;
    } else {
        my $jccl = join $j, map {$_ice->($ccls->[$_], $_ == @$ccls-1 ? 3:2)}
            0..@$ccls-1;
        {
            local $cd->{ccls} = [];
            local $cd->{_debug_ccl_note} = join(
                " ",
                ($dmin_ok  ? "min_ok=$min_ok"   : ""),
                ($dmax_ok  ? "max_ok=$max_ok"   : ""),
                ($dmin_nok ? "min_nok=$min_nok" : ""),
                ($dmax_nok ? "max_nok=$max_nok" : ""),
            );
            my $tmperrmsg;
            for ($tmperrmsg) {
                $_ = "TMPERRMSG:";
                $_ .= $cd->{clause} ? " clause $cd->{clause}" : " cset";
                $_ .= " min_ok=$min_ok"   if $dmin_ok;
                $_ .= " max_ok=$max_ok"   if $dmax_ok;
                $_ .= " min_nok=$min_nok" if $dmin_nok;
                $_ .= " max_nok=$max_nok" if $dmax_nok;
            }
            $self->add_ccl(
                $cd,
                "do { my \$${vp}ok=0; my \$${vp}nok=0;\n".
                    SHARYANTO::String::Util::indent(
                        $self->indent_character,
                        $jccl,
                    )." }",
                {
                    err_msg => $tmperrmsg,
                    ok_err_msg => '',
                }
            );
            $_ice->($cd->{ccls}[0]);
        }

    }
}

sub before_all_clauses {
    my ($self, $cd) = @_;

    $self->SUPER::before_clause_set($cd)
        if $self->can("SUPER::before_all_clause_set");

    # handle default/prefilters/req/forbidden clauses

    my $dt    = $cd->{data_term};
    my $csets = $cd->{csets};

    # handle default
    for my $i (0..@$csets-1) {
        my $cset  = $csets->[$i];
        my $def   = $cset->{default};
        my $defie = $cset->{"default.is_expr"};
        if (defined $def) {
            local $cd->{_debug_ccl_note} = "default #$i";
            my $ct = $defie ?
                $self->expr($def) : $self->literal($def);
            $self->add_ccl(
                $cd,
                "(($dt //= $ct), 1)",
                {err_msg => ""},
            );
        }
        delete $cd->{ucsets}[$i]{"default"};
        delete $cd->{ucsets}[$i]{"default.is_expr"};
    }

    # XXX handle prefilters

    # handle req
    my $has_req;
    for my $i (0..@$csets-1) {
        my $cset  = $csets->[$i];
        my $req   = $cset->{req};
        my $reqie = $cset->{"req.is_expr"};
        my $req_err_msg = "TMPERRMSG: required data not specified";
        local $cd->{_debug_ccl_note} = "req #$i";
        if ($req && !$reqie) {
            $has_req++;
            $self->add_ccl(
                $cd, "defined($dt)",
                {
                    err_msg   => $req_err_msg,
                    err_level => 'fatal',
                },
            );
        } elsif ($reqie) {
            $has_req++;
            my $ct = $self->expr($req);
            $self->add_ccl(
                $cd, "!($ct) || defined($dt)",
                {
                    err_msg   => $req_err_msg,
                    err_level => 'fatal',
                },
            );
        }
        delete $cd->{ucsets}[$i]{"req"};
        delete $cd->{ucsets}[$i]{"req.is_expr"};
    }

    # handle forbidden
    my $has_fbd;
    for my $i (0..@$csets-1) {
        my $cset  = $csets->[$i];
        my $fbd   = $cset->{forbidden};
        my $fbdie = $cset->{"forbidden.is_expr"};
        my $fbd_err_msg = "TMPERRMSG: forbidden data specified";
        local $cd->{_debug_ccl_note} = "forbidden #$i";
        if ($fbd && !$fbdie) {
            $has_fbd++;
            $self->add_ccl(
                $cd, "!defined($dt)",
                {
                    err_msg   => $fbd_err_msg,
                    err_level => 'fatal',
                },
            );
        } elsif ($fbdie) {
            $has_fbd++;
            my $ct = $self->expr($fbd);
            $self->add_ccl(
                $cd, "!($ct) || !defined($dt)",
                {
                    err_msg   => $fbd_err_msg,
                    err_level => 'fatal',
                },
            );
        }
        delete $cd->{ucsets}[$i]{"forbidden"};
        delete $cd->{ucsets}[$i]{"forbidden.is_expr"};
    }

    if (!$has_req && !$has_fbd) {
        $cd->{_skip_undef} = 1;
        $cd->{_ccls_idx1} = @{$cd->{ccls}};
    }


    $self->_die($cd, "BUG: type handler did not produce _ccl_check_type")
        unless defined($cd->{_ccl_check_type});
    local $cd->{_debug_ccl_note} = "check type '$cd->{type}'";
    $self->add_ccl(
        $cd, $cd->{_ccl_check_type},
        {
            err_msg   => 'TMPERRMSG: type check failed',
            err_level => 'fatal',
        },
    );
}

sub after_all_clauses {
    my ($self, $cd) = @_;

    if (delete $cd->{_skip_undef}) {
        my $jccl = $self->join_ccls(
            $cd,
            [splice(@{ $cd->{ccls} }, $cd->{_ccls_idx1})],
        );
        local $cd->{_debug_ccl_note} = "skip if undef";
        $self->add_ccl(
            $cd,
            "!defined($cd->{data_term}) ? 1 : \n".
                SHARYANTO::String::Util::indent(
                    $self->indent_character,
                    $self->enclose_paren($jccl),
                ),
            {err_msg => ''},
        );
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

Derived from L<Data::Sah::Compiler::Prog>.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from Prog's arguments, this class supports these arguments:

=over 4

=back

=cut
