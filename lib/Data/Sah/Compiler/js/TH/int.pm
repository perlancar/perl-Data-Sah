package Data::Sah::Compiler::js::TH::int;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH::num';
with 'Data::Sah::Type::int';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;
    my $dt = $cd->{data_term};

    $cd->{_ccl_check_type} = "(typeof($dt)=='number' || parseInt($dt)==$dt)";
}

sub clause_div_by {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt % $ct == 0");
}

sub clause_mod {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt % $ct\[0] == $ct\[1]");
}

1;
# ABSTRACT: js's type handler for type "int"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
