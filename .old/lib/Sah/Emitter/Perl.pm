package Data::Schema::Emitter::Perl;
# ABSTRACT: Emit Perl code from Data::Schema schema

=head1 SYNOPSIS

    use Data::Schema;
    my $ds = new Data::Schema;
    my $perl = $ds->perl($schema);

    # forget defined subs and emit them again in the next emission
    $ds->emitters->{Perl}->forget_defined_subs;

=cut

use 5.010;
use Any::Moose;
use Data::Dump::OneLine;
use Log::Any qw($log);
extends 'Data::Schema::Emitter::ProgBase';

sub BUILD {
    my ($self, @args) = @_;
    my $cfg = $self->config;

    $cfg->indent(4) unless defined($cfg->indent);
    $cfg->namespace('Data::Schema::compiled') unless defined($cfg->namespace);
    $cfg->sub_prefix('') unless defined($cfg->sub_prefix);
    $cfg->comment_style('shell') unless defined($cfg->comment_style);

    $self->expr_compiler( Language::Expr::Compiler::Perl->new );
    $self->expr_compiler->hook_var(
        sub {
            '$arg_'.$_[0];
        }
    );
    $self->expr_compiler->hook_func(
        sub {
            my ($name, @args) = @_;
            die "Unknown function $name" unless $self->main->func_names->{$name};
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
    return $res if ref($res) eq 'HASH' && $res->{SKIP_EMIT};

    my $subname = $self->subname($args{schema});
    $self->define_sub_start($subname);
    $self->line('my ($data, $res) = @_;');
    if ($self->config->report_all_errors) {
        $self->line('unless (defined($res)) {',
                    '$res = { success => 0, errors => [], warnings => [], } }');
    }
    $self->line('my $arg;');
    $self->line;
    $self->line('ATTRS:')->line('{')->inc_indent;
    $self->line;
};

after define_sub_start => sub {
    my ($self, $subname, $comment) = @_;
    $self->line("sub $subname {")->inc_indent;
};

before define_sub_end => sub {
    my ($self) = @_;
    $self->dec_indent->line("}");
};

sub on_expr {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $expr0 = $attr->{properties}{expr};
    my $expr = $attr->{name} eq 'check' ? $attr->{value} : $expr0;
    $self->line('$arg = ', $self->expr_compiler->perl($expr), ';');
    $attr->{value} = '$arg';
}

after before_attr => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    $self->line("my \$arg_$attr->{name} = $attr->{value};") if $attr->{depended_by};
};

before on_end => sub {
    my ($self, %args) = @_;
    $self->dec_indent->line('}');
    if ($self->config->report_all_errors) {
        $self->line('$res->{success} = !@{ $res->{errors} };');
    }
    $self->line('$res;');


#        $self->line('package ', $self->config->namespace, ';') if $self->config->namespace;
#        $self->load_module("boolean");
#        $self->load_module("Scalar::Util");

};

after load_module => sub {
    my ($self, $name) = @_;
    $self->line("use $name;");
};

sub preamble {
    my ($self) = @_;

    $self->line('package ', $self->config->namespace, ';')
        if $self->config->namespace;
    $self->load_module("boolean");
    $self->load_module("Scalar::Util");
    $self->line;
}

# ---

sub dump {
    my $self = shift;
    return Data::Dump::OneLine::dump_one_line(@_);
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
    my ($self, $attr, $cond, $extra) = @_;
    # XXX ATTR?errmsg, ?errmsg, ATTR?warnmsg, ?warnmsg
    my $errmsg = "XXX err $attr->{type}'s $attr->{name}"; # $self->main->emitters->{Human}->emit($attr...)
    if ($self->config->report_all_errors) {
        $self->line("if ($cond) { ", 'push @{ $res->{errors} }, ',
                    $self->dump($errmsg), ($extra ? "; $extra" : ""), " }");
    } else {
        $self->line("if ($cond) { return ", $self->dump($errmsg), " }");
    }
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
