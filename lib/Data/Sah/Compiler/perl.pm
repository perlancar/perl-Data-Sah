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
}

sub name { "perl" }

sub compile {
    my ($self, %args) = @_;

    $self->expr_compiler->hook_var(
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

sub init_cd {
    my ($self, %args) = @_;

    my $cd = $self->SUPER::init_cd(%args);
    $cd->{vars}  = {};

    $cd;
}

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

# enclose expression with parentheses, unless it already is
sub enclose_paren {
    my ($self, $expr) = @_;
    $expr =~ /\A\s*\(.+\)\s*\z/os ? $expr : "($expr)";
}

# TODO: support expression for {min,max}_{ok,nok} attributes. to do this we need
# to introduce scope so that (local $ok=0,$nok=0) can be nested.
sub join_exprs {
    my ($self, $exprs, $min_ok, $max_ok, $min_nok, $max_nok) = @_;
    my $dmin_ok  = defined($min_ok);
    my $dmax_ok  = defined($max_ok);
    my $dmin_nok = defined($min_nok);
    my $dmax_nok = defined($max_nok);

    return "" unless @$exprs;

    if (@$exprs==1 &&
            !$dmin_ok && $dmax_ok && $max_ok==0 && !$dmin_nok && !$dmax_nok) {
        # special case for NOT
        return "!" . $self->enclose_paren($exprs->[0]);
    } elsif (!$dmin_ok && !$dmax_ok && !$dmin_nok && (!$dmax_nok||$max_nok==0)){
        # special case for AND
        return join " && ", map { $self->enclose_paren($_) } @$exprs;
    } elsif ($dmin_ok && $min_ok==1 && !$dmax_ok && !$dmin_nok && !$dmax_nok) {
        # special case for OR
        return join " || ", map { $self->enclose_paren($_) } @$exprs;
    } else {
        my @ee;
        for (my $i=0; $i<@$exprs; $i++) {
            my $e = "";
            if ($i == 0) {
                $e .= '(local $ok=0, $nok=0), ';
            }
            $e .= $self->enclose_paren($exprs->[$i]).' ? $ok++:$nok++';

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
        return join " && ", map { $self->enclose_paren($_) } @ee;
    }
}

sub add_expr {
    my ($self, $cd, $expr) = @_;

    $self->enclose_paren($expr);
}

sub before_input {
    my ($self, $cd) = @_;
    $cd->{input}{term} //= '$'.$cd->{input}{name};
    $cd->{exprs} = [];
}

#after before_clause => sub {
#    my ($self, %args) = @_;
#    my $clause = $args{clause};
#    $self->line("my \$arg_$clause->{name} = $clause->{value};")
#        if $clause->{depended_by};
#};

#sub var {
#    my ($self, @arg) = @_;
#
#    while (my $n = shift @arg) {
#        die "Bug: invalid variable name $n" unless $n =~ /^[A-Za-z_]\w*$/;
#        my $v = shift @arg;
#        if (defined($v)) {
#            if ($self->states->{sub_vars}{$n}) {
#                $self->line("\$$n = ", $self->dump($v), ";");
#            } else {
#                $self->line("my \$$n = ", $self->dump($v), ";");
#            }
#        } elsif (!$self->states->{sub_vars}{$n}) {
#            $self->line("my \$$n;");
#        }
#        $self->states->{sub_vars}{$n}++;
#    }
#}

#sub errif {
#    my ($self, $clause, $cond, $extra) = @_;
#    # XXX CLAUSE:errmsg, :errmsg, CLAUSE:warnmsg, :warnmsg
#    my $errmsg = "XXX err $clause->{type}'s $clause->{name}"; # $self->main->compilers->{Human}->emit($clause...)
#    if (0 && $self->report_all_errors) {
#        $self->line("if ($cond) { ", 'push @{ $res->{errors} }, ',
#                    $self->dump($errmsg), ($extra ? "; $extra" : ""), " }");
#    } else {
#        $self->line("if ($cond) { return ", $self->dump($errmsg), " }");
#    }
#}

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
