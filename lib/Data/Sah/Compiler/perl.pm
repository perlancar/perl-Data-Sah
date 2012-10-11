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

sub compile {
    my ($self, %args) = @_;

    $self->expr_compiler->compiler->hook_var(
        sub {
            $_[0];
        }
    );
    #$self->expr_compiler->hook_func(
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

sub after_input {
    my ($self, $cd) = @_;
    for (
}

# as wel as enclose_paren
sub _insert_warn_or_error_msg_to_expr {
    my ($self, $which, $cd, $expr, $msg, $vrt) = @_;
    my $et = $cd->{input}{err_term};

    if ($vrt eq 'full' && $which eq 'warn' && defined($msg)) {
        return "(".$self->enclose_paren($expr).
            ", push \@{ $et"."->{warnings} }, ".$self->literal($msg).
                ", 1)";
    } elsif ($vrt eq 'full' && defined($msg)) {
        return "(".$self->enclose_paren($expr).
            " ? 1 : (push \@{ $et"."->{errors} }, ".$self->literal($msg).
                ", 1))";
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

# add expr to exprs, prevent shortcut if err_level='warn'. stick error message
# along with the expression, jor joining later.
sub add_expr {
    my ($self, $cd, $expr0) = @_;
    my $clause = $cd->{clause};
    my $vrt    = $cd->{args}{validator_return_type};
    my $el     = $cd->{cset}{"$clause.err_level"} // "error";
    delete $cd->{ucset}{"$clause.err_level"};
    my $em     = $cd->{cl_err_msg};

    my $expr;
    if ($el eq 'warn') {
        if ($vrt eq 'full') {
            $expr = $self->_insert_warn_msg_to_expr($cd, $expr0, $em, $vrt);
        } else {
            $expr = "(".$self->enclose_paren($expr0).", 1)";
        }
    } else {
        $expr = $expr0;
    }

    push @{ $cd->{exprs} }, [$expr, $cd->{cl_err_msg}];
}

# join exprs to handle {min,max}_{ok,nok} and insert error messages
sub join_exprs {
    my ($self, $cd, $exprs, $min_ok, $max_ok, $min_nok, $max_nok) = @_;
    $log->errorf("TMP:exprs=%s", $exprs);
    my $dmin_ok  = defined($min_ok);
    my $dmax_ok  = defined($max_ok);
    my $dmin_nok = defined($min_nok);
    my $dmax_nok = defined($max_nok);

    # TODO: support expression for {min,max}_{ok,nok} attributes. to do this we
    # need to introduce scope so that (local $ok=0,$nok=0) can be nested.

    return "" unless @$exprs;

    my $vrt = $cd->{args}{validator_return_type};

    if (@$exprs==1 &&
            !$dmin_ok && $dmax_ok && $max_ok==0 && !$dmin_nok && !$dmax_nok) {
        # special case for NOT
        return "!" . $self->_insert_error_msg_to_expr(
            $cd, $exprs->[0][0], $exprs->[0][1], $vrt);
    } elsif (!$dmin_ok && !$dmax_ok && !$dmin_nok && (!$dmax_nok||$max_nok==0)){
        # special case for AND
        return join " && ", map { $self->_insert_error_msg_to_expr(
            $cd, $_->[0], $_->[1], $vrt) } @$exprs;
    } elsif ($dmin_ok && $min_ok==1 && !$dmax_ok && !$dmin_nok && !$dmax_nok) {
        # special case for OR
        return join " || ", map { $self->_insert_error_msg_to_expr(
        $cd, $_->[0], $_->[1], $vrt) } @$exprs;
    } else {
        my @ee;
        for (my $i=0; $i<@$exprs; $i++) {
            my $e = "";
            if ($i == 0) {
                $e .= '(local $ok=0, $nok=0), ';
            }
            $e .= $self->enclose_paren($exprs->[$i][0]).' ? $ok++:$nok++';

            my @oee;
            push @oee, '$ok <= '. $max_ok  if $dmax_ok;
            push @oee, '$nok <= '.$max_nok if $dmax_nok;
            if ($i == @$exprs-1) {
                push @oee, '$ok >= '. $min_ok  if $dmin_ok;
                push @oee, '$nok >= '.$min_nok if $dmin_nok;
            }
            push @oee, '1' if !@oee;
            $e .= ", ".join(" && ", @oee);

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

        return join " && ", map { $self->_insert_error_msg_to_expr(
            $cd, $_, $tmperrmsg, $vrt) } @ee;
    }
}

1;
# ABSTRACT: Compile Sah schema to Perl code

=for Pod::Coverage BUILD add_paren

=head1 SYNOPSIS

 use Data::Sah;
 my $sah = Data::Sah->new;
 my $res = $sah->perl(
     inputs => [
         {name=>'arg1', schema=>'int*'},
         {name=>'arg2', schema=>[array=>{of=>'int*'}]},
     ],
     # other options ...
 );


=head1 DESCRIPTION


=head1 METHODS

=head2 new() => OBJ

=head2 $c->compile(%args) => RESULT

Aside from BaseProg's arguments, this class supports these arguments:

=over 4

=back

=cut
