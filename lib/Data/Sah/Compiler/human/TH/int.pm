package Data::Sah::Compiler::human::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::num';
with 'Data::Sah::Type::int';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $c->add_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} =
        "Scalar::Util::looks_like_number($dt) =~ " . '/^(?:1|2|9|10|4352)$/';
}

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->handle_clause(
        $cd,
        on_term => sub {
            my ($self, $cd) = @_;
            my $ct = $cd->{cl_term};
            my $dt = $cd->{data_term};

            $c->add_ccl($cd, "$dt % $ct == 0");
        },
    );
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

=cut
