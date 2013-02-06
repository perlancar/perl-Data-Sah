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

sub expr_defined {
    my ($self, $t) = @_;
    "defined($t)";
}

sub expr_array_subscript {
    my ($self, $at, $idxt) = @_;
    "$at->\[$idxt]";
}

sub expr_last_elem {
    my ($self, $at, $idxt) = @_;
    "$at->\[-1]";
}

sub expr_push {
    my ($self, $at, $elt) = @_;
    "push(\@{$at}, $elt)";
}

sub expr_pop {
    my ($self, $at, $elt) = @_;
    "pop(\@{$at})";
}

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

# $l //= $r
sub expr_setif {
    my ($self, $l, $r) = @_;
    "$l //= $r";
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

# wrap statements into an expression
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

# whether block is implemented using function
sub block_uses_sub { 0 }

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
        "return($_[0]);";
    } else {
        'return;';
    }
}

sub expr_validator_sub {
    my ($self, %args) = @_;

    my $aref = delete $args{accept_ref};
    if ($aref) {
        $args{var_term}  = '$ref_data';
        $args{data_term} = '$$ref_data';
    } else {
        $args{var_term}  = '$data';
        $args{data_term} = '$data';
    }

    $self->SUPER::expr_validator_sub(%args);
}

1;
# ABSTRACT: Compile Sah schema to Perl code

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|literal|expr_.+|stmt_.+)$

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
