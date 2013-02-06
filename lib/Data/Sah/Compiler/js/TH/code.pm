package Data::Sah::Compiler::js::TH::code;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::code';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "typeof($dt)=='function'";
}

1;
# ABSTRACT: js's type handler for type "code"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
