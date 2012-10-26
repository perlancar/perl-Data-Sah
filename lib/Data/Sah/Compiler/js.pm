package Data::Sah::Compiler::js;

use 5.010;
use Moo;
use Log::Any qw($log);
extends 'Data::Sah::Compiler::Prog';

# VERSION

sub BUILD {
    my ($self, $args) = @_;

    $self->comment_style('cpp');
    $self->indent_character(" " x 2);
    $self->var_sigil('');
}

sub name { "js" }

sub literal {
    require JSON;
    state $json = JSON->new->allow_nonref;

    my ($self, $val) = @_;
    $json->encode($val);
}

sub expr {
    my ($self, $expr) = @_;
    $self->expr_compiler->js($expr);
}

sub compile {
    my ($self, %args) = @_;

    $self->expr_compiler->js_compiler->hook_var(
        sub {
            $_[0];
        }
    );
    #$self->expr_compiler->js_compiler->hook_func(
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

# as wel as enclose_paren
sub _insert_warn_or_error_msg_to_expr {
    my ($self, $which, $cd, $expr, $msg, $vrt, $opts) = @_;
    my $et = $cd->{args}{err_term};

    my $ret = $opts->{force_shortcut} ? 0 : 1;

    if ($vrt eq 'full' && $which eq 'warn' && defined($msg)) {
        return "(".$self->enclose_paren($expr).
            ", $et".".warnings.push(".$self->literal($msg)."), 1)";
    } elsif ($vrt eq 'full' && defined($msg)) {
        return "(".$self->enclose_paren($expr).
            " ? 1 : ($et".".warnings.push(".$self->literal($msg)."), $ret)";
    } elsif ($vrt eq 'str' && defined($msg)) {
        return "(".$self->enclose_paren($expr).
            " ? 1 : ($et = ".$self->literal($msg).", 0)";
    } else {
        return $self->enclose_paren($expr);
    }
}

sub _insert_warn_msg_to_expr {
    my $self = shift;
    $self->_insert_warn_or_error_msg_to_expr('warn', @_);
}

sub _insert_error_msg_to_expr {
    my $self = shift;
    $self->_insert_warn_or_error_msg_to_expr('error', @_);
}

# add compiled clause to ccls, prevent shortcut if err_level='warn'. stick error
# message along with the expression, jor joining later.
sub add_ccl {
    my ($self, $cd, $expr0, $opts) = @_;
    $opts //= {};
    my $clause = $cd->{clause};
    my $vrt    = $cd->{args}{validator_return_type};
    my $el     = $cd->{cset}{"$clause.err_level"} // "error";
    delete $cd->{ucset}{"$clause.err_level"};
    my $em     = $cd->{cl_err_msg};

    my $expr;
    if ($el eq 'warn') {
        if ($vrt eq 'full') {
            $expr = $self->_insert_warn_msg_to_expr(
                $cd, $expr0, $em, $vrt, $opts);
        } else {
            $expr = "(".$self->enclose_paren($expr0).", 1)";
        }
    } else {
        $expr = $expr0;
    }

    push @{ $cd->{ccls} }, [$expr, $cd->{cl_err_msg}];
}

# join ccls to handle {min,max}_{ok,nok} and insert error messages. opts =
# newline (bool, default 0)
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

    # default is AND
    $max_nok = 0 if !$dmin_ok && !$dmax_ok && !$dmin_nok && !$dmax_nok;

    # TODO: support expression for {min,max}_{ok,nok} attributes. to do this we
    # need to introduce scope so that (local $ok=0,$nok=0) can be nested.

    return "" unless @$ccls;

    my $vrt = $cd->{args}{validator_return_type};

    my $j = " && " . (
        $opts->{newline} ?
            "\n" . ($self->indent_character x $cd->{indent_level}) : "");
    my $j2 = " && " . (
        $opts->{newline} ?
            "\n" . ($self->indent_character x ($cd->{indent_level}+1)) : "");

    if (@$ccls==1 &&
            !$dmin_ok && $dmax_ok && $max_ok==0 && !$dmin_nok && !$dmax_nok) {
        # special case for NOT
        return "!" . $self->_insert_error_msg_to_expr(
            $cd, $ccls->[0][0], $ccls->[0][1], $vrt);
    } elsif (!$dmin_ok && !$dmax_ok && !$dmin_nok && (!$dmax_nok||$max_nok==0)){
        # special case for AND
        return join $j, map { $self->_insert_error_msg_to_expr(
            $cd, $_->[0], $_->[1], $vrt) } @$ccls;
    } else {
        my @ee;
        for (my $i=0; $i<@$ccls; $i++) {
            my $e = "";
            if ($i == 0) {
                #$e .= '(ok=0, nok=0), ';
            }
            $e .= $self->enclose_paren($ccls->[$i][0]).' ? ok++:nok++';

            my @oee;
            push @oee, 'ok <= '. $max_ok  if $dmax_ok;
            push @oee, 'nok <= '.$max_nok if $dmax_nok;
            if ($i == @$ccls-1) {
                push @oee, 'ok >= '. $min_ok  if $dmin_ok;
                push @oee, 'nok >= '.$min_nok if $dmin_nok;
            }
            push @oee, '1' if !@oee;
            $e .= ", ".join($j2, @oee);

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

        return join $j, map { $self->_insert_error_msg_to_expr(
            $cd, $_, $tmperrmsg, $vrt) } @ee;
    }
}

1;
# ABSTRACT: Compile Sah schema to JavaScript code

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
