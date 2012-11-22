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

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        type => 'clause',
        fmt  => 'be divisible by %s',
    });
}

sub clause_mod {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            $c->add_ccl($cd, "$dt % $ct\->[0] == $ct\->[1]");
        },
    );
}

1;
# ABSTRACT: perl's type handler for type "int"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
