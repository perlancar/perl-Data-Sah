package Data::Sah::Compiler::js;

use 5.010;
use Moo;
extends 'Data::Sah::Compiler::Prog';
use Log::Any qw($log);

use SHARYANTO::String::Util;

# VERSION

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('cpp');
    $self->indent_character(" " x 4);
    $self->var_sigil("");
    $self->concat_op("+");
}

sub name { "js" }

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->js($expr);
}

sub literal {
    my ($self, $val) = @_;

    state $json = do {
        require JSON;
        JSON->new->allow_nonref;
    };

    # we need cleaning since json can't handle qr//, for one.
    state $cleanser = do {
        require Data::Clean::JSON;
        Data::Clean::JSON->new;
    };

    $json->encode($cleanser->clone_and_clean($val));
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

sub expr_defined {
    my ($self, $t) = @_;
    "!($t === undefined || $t === null)";
}

sub expr_push_dpath_before_expr {
    my ($self, $vt, $e) = @_;
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
        $self->expr_setif("$et\['$k'][_sahv_dpath.join('/')]", $err_expr),
        ")",
    );
}

sub expr_reset_err_str {
    my ($self, $et, $err_expr) = @_;
    "($et = null, true)";
}

sub expr_reset_err_full {
    my ($self, $et) = @_;
    join(
        "",
        "(",
        $self->expr_setif("$et\['errors']", "{}"),
        ",",
        "delete($et\['errors'][_sahv_dpath.join('/')])",
        ")",
    );
}

sub expr_log {
    my ($self, $cd, $ccl) = @_;
    # currently not supported
    "";
}

sub expr_block {
    my ($self, $code) = @_;
    join(
        "",
        "(function() {\n",
        SHARYANTO::String::Util::indent(
            $self->indent_character,
            $code,
        ),
        "})()",
    );
}

# whether block is implemented using function
sub block_uses_sub { 1 }

sub stmt_declare_local_var {
    my $self = shift;
    my $v = shift;
    if (@_) {
        "var $v = $_[0];";
    } else {
        "var $v;";
    }
}

sub expr_anon_sub {
    my ($self, $args, $code) = @_;
    join(
        "",
        "function(".join(", ", @$args).") {\n",
        SHARYANTO::String::Util::indent(
            $self->indent_character,
            $code,
        ),
        "}"
    );
}

sub stmt_require_module {
    my ($self, $mod) = @_;
    # currently loading module is not supported by js?
    #"require $mod;";
    '';
}

sub stmt_require_log_module {
    my ($self, $mod) = @_;
    # currently logging is not supported by js
    '';
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

    $args{data_term} = 'data';
    $self->SUPER::expr_validator_sub(%args);
}

1;
# ABSTRACT: Compile Sah schema to JavaScript code

=for Pod::Coverage BUILD ^(after_.+|before_.+|name|expr|expr_.+|stmt_.+)$

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
