package Data::Sah::Compiler::perl::TH::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::int';

# VERSION

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
