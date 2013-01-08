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

    #$self->expr_compiler->compiler->hook_var(
    #    sub {
    #        $_[0];
    #    }
    #);

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
# .err_level if not specified), err_expr, err_msg (str, the default will be
# produced by human compiler if not supplied, or taken from current clause's
# .err_msg)
sub add_ccl {
    my ($self, $cd, $ccl, $opts) = @_;
    $opts //= {};
    my $clause = $cd->{clause} // "";
    my $op     = $cd->{cl_op} // "";

    my $el = $opts->{err_level} // $cd->{clset}{"$clause.err_level"} // "error";
    my $err_expr = $opts->{err_expr};
    my $err_msg  = $opts->{err_msg};

    if (defined $err_expr) {
        #
    } else {
        unless (defined $err_msg) { $err_msg = $cd->{clset}{"$clause.err_msg"} }
        unless (defined $err_msg) {
            my $path = join(".", @{$cd->{path}});
            # XXX how to invert on op='none' or op='not'?

            my @msgpath = @{$cd->{path}};
            my $msgpath;
            my $hc  = $cd->{_hc};
            my $hcd = $cd->{_hcd};
            while (1) {
                # search error message, use more general one if the more
                # specific one is not available
                last unless @msgpath;
                $msgpath = join(".", @msgpath);
                my $ccls = $hcd->{result}{$msgpath};
                pop @msgpath;
                if ($ccls) {
                    local $hcd->{args}{format} = 'inline_text';
                    if (ref($ccls) eq 'HASH' && $ccls->{type} eq 'noun') {
                        my $f = $hc->_xlt($hcd, "Input is not of type %s");
                        $err_msg = 1 . sprintf(
                            $f,
                            $hc->format_ccls($hcd, $ccls),
                        );
                    } else {
                        $err_msg = $hc->format_ccls($hcd, $ccls);
                        #use Data::Dump 'dump'; $err_msg = dump($ccls); #DEBUG
                    }
                    last;
                }
            }
            if (!$err_msg) {
                $err_msg = "ERR: at $path";
            } else {
                $err_msg = ucfirst($err_msg);
                $err_msg = "[path=$path, msgpath=$msgpath] $err_msg"
                    if $cd->{args}{debug};
            }
        }
        $err_expr = $self->literal($err_msg) if $err_msg;
    }

    my $rt = $cd->{args}{return_type};
    my $et = $cd->{args}{err_term};
    my $err_code;
    if ($rt eq 'full') {
        my $k = $el eq 'warn' ? 'warnings' : 'errors';
        $err_code = "push \@{ $et\->{$k} }, $err_expr" if $err_expr;
    } elsif ($rt eq 'str') {
        if ($el ne 'warn') {
            $err_code = "$et //= $err_expr" if $err_expr;
        }
    }

    my $res = {
        ccl             => $ccl,
        err_level       => $el,
        err_code        => $err_code,
        (_debug_ccl_note => $cd->{_debug_ccl_note}) x !!$cd->{_debug_ccl_note},
    };
    push @{ $cd->{ccls} }, $res;
    delete $cd->{uclset}{"$clause.err_level"};
    delete $cd->{uclset}{"$clause.err_msg"};
}

# join ccls to handle .op and insert error messages. opts = op
sub join_ccls {
    my ($self, $cd, $ccls, $opts) = @_;
    $opts //= {};
    my $op = $opts->{op} // "and";

    my ($min_ok, $max_ok, $min_nok, $max_nok);
    if ($op eq 'and') {
        $max_nok = 0;
    } elsif ($op eq 'or') {
        $min_ok = 1;
    } elsif ($op eq 'none') {
        $max_ok = 0;
    } elsif ($op eq 'not') {

    }
    my $dmin_ok  = defined($min_ok);
    my $dmax_ok  = defined($max_ok);
    my $dmin_nok = defined($min_nok);
    my $dmax_nok = defined($max_nok);

    return "" unless @$ccls;

    my $rt      = $cd->{args}{return_type};
    my $vp      = $cd->{args}{var_prefix};
    my $ichar   = $self->indent_character;
    my $indent  = $ichar x $cd->{indent_level};
    my $indent2 = $ichar x ($cd->{indent_level}+1);

    my $j  = "\n$indent  &&\n";
    my $j2 = "\n$indent2  &&\n";

    # insert comment, error message, and $ok/$nok counting. $which is 0 by
    # default (normal), or 1 (reverse logic, for 'not' or 'none'), or 2 (for
    # $ok/$nok counting), or 3 (like 2, but for the last clause).
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
            $ec = $ccl->{err_code};
            $ret = $ccl->{err_level} eq 'fatal' ? 0 :
                $rt eq 'full' || $ccl->{err_level} eq 'warn' ? 1 : 0;
            if ($rt eq 'bool' && $ret) {
                $res .= "1";
            } elsif ($rt eq 'bool' || !$ccl->{err_code}) {
                $res .= $self->enclose_paren($e);
            } else {
                $res .= $self->enclose_paren(
                    $self->enclose_paren($e) . " ? 1 : (($ec),$ret)",
                    "force");
            }
        }
        $res;
    };

    if ($op eq 'not') {
        return $_ice->($ccls->[0], 1);
    } elsif ($op eq 'and') {
        return join $j, map { $_ice->($_) } @$ccls;
    } elsif ($op eq 'none') {
        return join $j, map { $_ice->($_, 1) } @$ccls;
    } else {
        my $jccl = join $j, map {$_ice->($ccls->[$_], $_ == @$ccls-1 ? 3:2)}
            0..@$ccls-1;
        {
            local $cd->{ccls} = [];
            local $cd->{_debug_ccl_note} = "op=$op";
            $self->add_ccl(
                $cd,
                "do { my \$${vp}ok=0; my \$${vp}nok=0;\n".
                    SHARYANTO::String::Util::indent(
                        $self->indent_character,
                        $jccl,
                    )." }",
                {
                }
            );
            $_ice->($cd->{ccls}[0]);
        }
    }
}

sub _xlt {
    my ($self, $cd, $fmt, $vals) = @_;
    $vals //= [];

    my $hc  = $self->{_hc};
    my $hcd = $self->{_hcd};
    if ($hcd) {
        $fmt = $hc->_xlt($hcd, $fmt);
        return Text::sprintfn::sprintfn($fmt, {}, @$vals);
    } else {
        return $fmt;
    }
}

sub before_handle_type {
    my ($self, $cd) = @_;

    # do a human compilation first to collect all the error messages

    unless ($cd->{_inner}) {
        my $hc = $cd->{_hc};
        my %hargs = %{$cd->{args}};
        $hargs{format}               = 'msg_catalog';
        $hargs{schema_is_normalized} = 1;
        $hargs{schema}               = $cd->{nschema};
        $hargs{on_unhandled_clause}  = 'ignore';
        $hargs{on_unhandled_attr}    = 'ignore';
        $cd->{_hcd} = $hc->compile(%hargs);
    }
}

sub before_all_clauses {
    my ($self, $cd) = @_;

    $self->SUPER::before_clause_set($cd)
        if $self->can("SUPER::before_all_clause_set");

    # handle default/prefilters/req/forbidden clauses

    my $dt     = $cd->{data_term};
    my $clsets = $cd->{clsets};

    # handle default
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $def    = $clset->{default};
        my $defie  = $clset->{"default.is_expr"};
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
        delete $cd->{uclsets}[$i]{"default"};
        delete $cd->{uclsets}[$i]{"default.is_expr"};
    }

    # XXX handle prefilters

    # handle req
    my $has_req;
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $req    = $clset->{req};
        my $reqie  = $clset->{"req.is_expr"};
        my $req_err_msg = $self->_xlt($cd, "Required input not specified");
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
        delete $cd->{uclsets}[$i]{"req"};
        delete $cd->{uclsets}[$i]{"req.is_expr"};
    }

    # handle forbidden
    my $has_fbd;
    for my $i (0..@$clsets-1) {
        my $clset  = $clsets->[$i];
        my $fbd    = $clset->{forbidden};
        my $fbdie  = $clset->{"forbidden.is_expr"};
        my $fbd_err_msg = $self->_xlt($cd, "Forbidden input specified");
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
        delete $cd->{uclsets}[$i]{"forbidden"};
        delete $cd->{uclsets}[$i]{"forbidden.is_expr"};
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
            err_msg   => sprintf(
                $self->_xlt($cd, "Input is not of type %s"),
                $self->_xlt(
                    $cd,
                    $cd->{_hc}->get_th(name=>$cd->{type})->name //
                        $cd->{type}
                    ),
            ),
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

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|literal|add_ccl|join_ccls|xlt)$

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
