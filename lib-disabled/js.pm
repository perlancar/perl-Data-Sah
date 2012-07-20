package Data::Sah::Compiler::js;

use 5.010;
use Moo;
use Log::Any qw($log);
extends 'Data::Sah::Compiler::BaseProg';

1;
#ABSTRACT: Compile Sah schema to JavaScript code

use Data::Dump::OneLine qw(dump1);

has namespace => (is => 'rw', default => 'Data::Sah::compiled');

sub BUILD {
    my ($self, @args) = @_;

    $self->indent_size(4)             unless defined($self->indent_size);
    $self->sub_prefix('')             unless defined($self->sub_prefix);
    $self->comment_style('shell')     unless defined($self->comment_style);

    $self->expr_compiler( Language::Expr::Compiler::Perl->new );
    $self->expr_compiler->hook_var(
        sub {
            '$arg_'.$_[0];
        }
    );
    $self->expr_compiler->hook_func(
        sub {
            my ($name, @args) = @_;
            die "Unknown function $name"
                unless $self->main->func_names->{$name};
            my $subname = "func_$name";
            $self->define_sub_start($subname);
            my $meth = "func_$name";
            $self->func_handlers->{$name}->$meth;
            $self->define_sub_end();
            $subname . "(" . join(", ", @args) . ")";
        }
    );
};

sub on_start {
    my ($self, %args) = @_;
    my $res = $self->SUPER::on_start(%args);
    return $res if $res->{SKIP_EMIT};

    my $subname = $self->subname($args{schema});
    $self->define_sub_start($subname);
    $self->line('my ($data, $res) = @_;');
    if (0 && $self->report_all_errors) {
        $self->line('unless (defined($res)) {',
                    '$res = { success => 0, errors => [], warnings => [], } }');
    }
    $self->line('my $arg;');
    $self->line;
    $self->line('CLAUSES:')->line('{')->inc_indent;
    $self->line;
};

# commented temporarily, unfinished refactoring
#after define_sub_start => sub {
#    my ($self, $subname, $comment) = @_;
#    $self->line("sub $subname {")->inc_indent;
#};
#
#before define_sub_end => sub {
#    my ($self) = @_;
#    $self->dec_indent->line("}");
#};

sub on_expr {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $expr0 = $clause->{clauses}{expr};
    my $expr = $clause->{name} eq 'check' ? $clause->{value} : $expr0;
    $self->line('$arg = ', $self->expr_compiler->perl($expr), ';');
    $clause->{value} = '$arg';
}

# commented temporarily, unfinished refactoring
#after before_clause => sub {
#    my ($self, %args) = @_;
#    my $clause = $args{clause};
#    $self->line("my \$arg_$clause->{name} = $clause->{value};")
#        if $clause->{depended_by};
#};
#
#before after_clause => sub {
#
#};
#
#before on_end => sub {
#    my ($self, %args) = @_;
#    $self->dec_indent->line('}');
#    if (0 && $self->report_all_errors) {
#        $self->line('$res->{success} = !@{ $res->{errors} };');
#    }
#    $self->line('$res;');


#        $self->line('package ', $self->namespace, ';') if $self->namespace;
#        $self->load_module("boolean");
#        $self->load_module("Scalar::Util");

# commented temporarily, unfinished refactoring
#};

# commented temporarily, unfinished refactoring
#after load_module => sub {
#    my ($self, $name) = @_;
#    $self->line("use $name;");
#};

sub preamble {
    my ($self) = @_;

    $self->line('package ', $self->namespace, ';')
        if $self->namespace;
    $self->load_module("boolean");
    $self->load_module("Scalar::Util");
    $self->line;
}

# ---

sub dump {
    my $self = shift;
    return dump1(@_);
}

sub var {
    my ($self, @arg) = @_;

    while (my $n = shift @arg) {
        die "Bug: invalid variable name $n" unless $n =~ /^[A-Za-z_]\w*$/;
        my $v = shift @arg;
        if (defined($v)) {
            if ($self->states->{sub_vars}{$n}) {
                $self->line("\$$n = ", $self->dump($v), ";");
            } else {
                $self->line("my \$$n = ", $self->dump($v), ";");
            }
        } elsif (!$self->states->{sub_vars}{$n}) {
            $self->line("my \$$n;");
        }
        $self->states->{sub_vars}{$n}++;
    }
}

sub errif {
    my ($self, $clause, $cond, $extra) = @_;
    # XXX CLAUSE:errmsg, :errmsg, CLAUSE:warnmsg, :warnmsg
    my $errmsg = "XXX err $clause->{type}'s $clause->{name}"; # $self->main->compilers->{Human}->emit($clause...)
    if (0 && $self->report_all_errors) {
        $self->line("if ($cond) { ", 'push @{ $res->{errors} }, ',
                    $self->dump($errmsg), ($extra ? "; $extra" : ""), " }");
    } else {
        $self->line("if ($cond) { return ", $self->dump($errmsg), " }");
    }
}

1;
# ABSTRACT: Compile schema to Perl code

=head1 SYNOPSIS

 use Data::Sah;
 my $sah = Data::Sah->new;
 my $code = $sah->perl(
     inputs => [
         {schema=>'int*', term=>'$arg1'},
         {schema=>'int*', term=>'$arg1'},
     ],
     # other options ...
 ); # return Perl code in string

=head1 DESCRIPTION
