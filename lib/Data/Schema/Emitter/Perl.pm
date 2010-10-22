package Data::Schema::Emitter::Perl;
# ABSTRACT: Emit Perl code from Data::Schema schema

=head1 SYNOPSIS

    use Data::Schema;
    my $ds = new Data::Schema;
    my $perl = $ds->perl($schema);

    # forget defined subs and emit them again in the next emission
    $ds->emitters->{Perl}->forget_defined_subs;

=cut

use Any::Moose;
use Data::Dumper;
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
};

sub on_start {
    my ($self, %args) = @_;
    my $res = $self->SUPER::on_start(%args);
    return $res if ref($res) eq 'HASH' && $res->{SKIP_EMIT};

    unless ($args{inner}) {
        $self->line('package ', $self->config->namespace, ';') if $self->config->namespace;
        $self->load_module("boolean");
        $self->load_module("Scalar::Util");
        #$self->define_sub();
    }

    my $subname = $self->subname($args{schema});
    $self->states->{defined_subs}{$subname} = 1;
    $self->line("sub $subname {")->inc_indent;
    $self->line('my ($data, $res) = @_;');
    $self->line('unless (defined($res)) { $res = { success => 0, errors => [], warnings => [], } }');
    $self->line('my $arg;');
    $self->line;
    $self->line('ATTRS:')->line('{')->inc_indent;
    $self->line;
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
    $self->line('$res->{success} = !@{ $res->{errors} };');
    $self->line('$res;');
    $self->dec_indent->line('}');
};

before load_module => sub {
    my ($self, $name) = @_;
    return if $self->states->{loaded_modules}{$name};
    $self->line("use $name;");
};

before define_sub => sub {
    my ($self, $name, $content) = @_;
    return if $self->states->{defined_subs}{$name};
    # XXX
};

# ---

sub dump {
    my ($self, @arg) = @_;
    join ", ", Data::Dumper->new([@arg])->Indent(0)->Terse(1)->Sortkeys(1)->Purity(0)->Dump();
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
    $self->line("if ($cond) { ", 'push @{ $res->{errors} }, ', $self->dump($errmsg), ($extra ? "; $extra" : ""), " }");
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
