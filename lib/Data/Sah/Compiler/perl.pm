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
    $self->concat_op(".");
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

sub true { "1" }

sub expr_push_dpath_before_expr {
    my ($self, $vt, $e) = @_;
    $self->enclose_paren("push(\@\$_sahv_dpath, $vt), $e");
}

sub expr_pop_dpath {
    my ($self) = @_;
    'pop(@$_sahv_dpath)';
}

sub expr_prefix_dpath {
    my ($self, $t) = @_;
    '(@$_sahv_dpath ? \'@\'.join("/",@$_sahv_dpath).": " : "") . ' . $t;
}

sub expr_set_err_str {
    my ($self, $et, $err_expr) = @_;
    "$et //= $err_expr";
}

sub expr_set_err_full {
    my ($self, $et, $k, $err_expr) = @_;
    "$et\->{$k}{join('/',\@\$_sahv_dpath)} //= $err_expr";
}

sub expr_reset_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et = undef, 1)";
}

sub expr_reset_err_full {
    my ($self, $et) = @_;
    "(delete($et\->{errors}{join('/',\@\$_sahv_dpath)}), 1)";
}

sub expr_log {
    my ($self, $cd, $ccl) = @_;

    $self->add_module($cd, 'Log::Any');
    "(\$log->tracef('%s ...', ".
        $self->literal($ccl->{_debug_ccl_note})."), 1)";
}

sub expr_block {
    my ($self, $code) = @_;
    join(
        "",
        "do {\n",
        SHARYANTO::String::Util::indent(
            $self->indent_character,
            $code,
        ),
        "}",
    );
}

sub stmt_declare_local_var {
    my ($self, $v, $vt) = @_;
    "my \$$v = $vt;";
}

sub expr_anon_sub {
    my ($self, $args, $code) = @_;
    join(
        "",
        "sub {\n",
        SHARYANTO::String::Util::indent(
            $self->indent_character,
            join(
                "",
                ("my(".join(", ", @$args).") = \@_;\n") x !!@$args,
                $code,
            ),
        ),
        "}"
    );
}

sub stmt_require_module {
    my ($self, $mod) = @_;
    "require $mod;";
}

sub stmt_require_log_module {
    my ($self, $mod) = @_;
    'use Log::Any qw($log);';
}

sub stmt_return {
    my $self = shift;
    if (@_) {
        "return $_[0];";
    } else {
        'return;';
    }
}

sub stmt_declare_validator_sub {
    my ($self, %args) = @_;

    my $aref = delete $args{accept_ref};
    if ($aref) {
        $args{var_term}  = '$ref_data';
        $args{data_term} = '$$ref_data';
    } else {
        $args{var_term}  = '$data';
        $args{data_term} = '$data';
    }

    $self->SUPER::stmt_declare_validator_sub(%args);
}

sub before_all_clauses {
    my ($self, $cd) = @_;

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
            "!defined($cd->{data_term}) ? 1 : \n\n".
                $self->enclose_paren($jccl),
            {err_msg => ''},
        );
    }

    $self->SUPER::after_all_clauses($cd)
        if $self->can("SUPER::after_all_clauses");
}

1;
# ABSTRACT: Compile Sah schema to Perl code

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|literal|expr_.+|)$

=head1 SYNOPSIS

 # see Data::Sah


=head1 DESCRIPTION

Derived from L<Data::Sah::Compiler::Prog>.


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from Prog's arguments, this class supports these arguments:

=over

=back

=cut
