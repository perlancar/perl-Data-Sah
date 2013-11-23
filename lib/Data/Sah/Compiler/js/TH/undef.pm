package Data::Sah::Compiler::js::TH::undef;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::undef';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "$dt === undefined || $dt === null";
}

1;
# ABSTRACT: js's type handler for type "re"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
