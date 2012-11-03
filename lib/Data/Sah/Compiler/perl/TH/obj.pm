package Data::Sah::Compiler::perl::TH::obj;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::obj';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $c->add_module($cd, 'Scalar::Util');
    $cd->{_ccl_check_type} = "Scalar::Util::blessed($dt)";
}

sub clause_can {
    my $self = shift;
    $self->_warn_unimplemented(@_);
}

sub clause_isa {
    my $self = shift;
    $self->_warn_unimplemented(@_);
}

1;
# ABSTRACT: perl's type handler for type "obj"

=cut
