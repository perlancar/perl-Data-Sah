package Data::Sah::Compiler::perl::TH::obj;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::obj';

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $c->add_runtime_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt)";
}

sub clause_can {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt->can($ct)");
}

sub clause_isa {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    $c->add_ccl($cd, "$dt->isa($ct)");
}

1;
# ABSTRACT: perl's type handler for type "obj"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
