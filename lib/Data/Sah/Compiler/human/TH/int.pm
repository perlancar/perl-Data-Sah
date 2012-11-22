package Data::Sah::Compiler::human::TH::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH::num';
with 'Data::Sah::Type::int';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        type  => 'noun',
        fmt   => ["integer", "integers"],
    });
}

# XXX div_by => 2 = even

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => q[%(modal_verb_be)sdivisible by %s],
        multi => 1,
        expr  => 1,
    });
}

# XXX mod => [2, 1] => odd

sub clause_mod {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $cv = $cd->{cl_value};
    $c->add_ccl($cd, {
        type => 'clause',
        fmt  => q[%(modal_verb)sleave a remainder of %2$s when divided by %1$s],
        vals => $cv,
    });
}

1;
# ABSTRACT: human's type handler for type "int"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
