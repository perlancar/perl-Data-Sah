package Data::Sah::Compiler::js;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::Prog';
with 'Data::Sah::Compiler::JSONLiteralRole';
use Log::Any qw($log);

use SHARYANTO::String::Util;

# VERSION

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('cpp');
    $self->indent_character(" " x 4);
    $self->concat_op("+");
}

sub name { "js" }

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->js($expr);
}

sub compile {
    my ($self, %args) = @_;

    #$self->expr_compiler->compiler->hook_var(
    # ...
    #);

    #$self->expr_compiler->compiler->hook_func(
    # ...
    #);

    $self->SUPER::compile(%args);
}

sub true { "true" }

sub expr_push_dpath_before_expr {
    my ($self, $vt) = @_;
    $self->enclose_paren('(_sahv_dpath.push($vt), '.$e);
}

sub code_pop_dpath {
    my ($self) = @_;
    '_sahv_dpath.pop()';
}

sub expr_prefix_dpath {
    my ($self, $t) = @_;
    '(_sahv_dpath.length ? "@" + _sahv_dpath.join("/") + ": " : "") + ' . $t;
}

sub expr_defined {
    my ($self, $t) = @_;
    "($t === undefined || $t === null)";
}

# $l //= $r
sub expr_setif {
    my ($self, $l, $r) = @_;
    "$l = " . $self->expr_defined($l) . " ? $l : $r";
}

sub expr_set_err_str {
    my ($self, $et, $err_expr) = @_;
    $self->expr_setif($et, $err_expr);
}

sub expr_set_err_full {
    my ($self, $et, $k, $err_expr) = @_;
    join(
        "",
        "(",
        $self->expr_setif("$et\['$k']", "{}"),
        ",",
        ")",
        $self->expr_setif("$et\['$k'][_sahv_dpath.join('/')]", $err_expr),
    );
}

sub expr_reset_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et = undefined, 1)";
}

sub expr_reset_err_full {
    my ($self, $et) = @_;
    "delete($et\['errors'][_sahv_dpath.join('/')])";
}

sub expr_log {
    my ($self, $cd, $ccl) = @_;
    # currently not supported
    "";
}

sub expr_block {
    my ($code) = @_;
    join(
        "",
        "function() {\n",
        SHARYANTO::String::Util::indent(
            $self->indent_character,
            $code,
        ),
        "}",
    );
}

sub stmt_declare_lexical_var {
    my ($code, $v, $vt) = @_;
    "var $v = $vt;";
}

sub expr_declare_sub {
}

1;
# ABSTRACT: Compile Sah schema to JavaScript code

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr)$

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
