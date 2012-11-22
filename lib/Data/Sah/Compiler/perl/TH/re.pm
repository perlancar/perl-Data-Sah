package Data::Sah::Compiler::perl::TH::re;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::re';

# VERSION

# XXX prefilter to convert string to regex object

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'Regexp' || !ref($dt) && ".
        "eval { my \$tmp = $dt; qr/\$tmp/; 1 }";
}

1;
# ABSTRACT: perl's type handler for type "re"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
