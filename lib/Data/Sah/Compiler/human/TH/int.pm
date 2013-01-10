package Data::Sah::Compiler::human::TH::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH::num';
with 'Data::Sah::Type::int';

# VERSION

sub name { "integer" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        type  => 'noun',
        fmt   => ["integer", "integers"],
    });
}

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    if (!$cd->{cl_is_multi} && !$cd->{cl_is_expr} &&
            $cv == 2) {
        $c->add_ccl($cd, {
            fmt   => q[%(modal_verb)s be even],
        });
        return;
    }

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb)s be divisible by %s],
        expr  => 1,
    });
}

sub clause_mod {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $cv = $cd->{cl_value};

    if (!$cd->{cl_is_multi} && !$cd->{cl_is_expr}) {
        if ($cv->[0] == 2 && $cv->[1] == 0) {
            $c->add_ccl($cd, {
                fmt   => q[%(modal_verb)s be even],
            });
        } elsif ($cv->[0] == 2 && $cv->[1] == 1) {
            $c->add_ccl($cd, {
                fmt   => q[%(modal_verb)s be odd],
            });
        }
        return;
    }

    $c->add_ccl($cd, {
        type => 'clause',
        fmt  =>
            q[%(modal_verb)s leave a remainder of %2$s when divided by %1$s],
        vals => $cv,
    });
}

1;
# ABSTRACT: human's type handler for type "int"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
