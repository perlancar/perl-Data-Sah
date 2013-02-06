package Data::Sah::Compiler::js::TH::re;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::re';

# VERSION

# XXX prefilter to convert string to regex object

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "$dt instanceof RegExp";
}

1;
# ABSTRACT: js's type handler for type "re"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
