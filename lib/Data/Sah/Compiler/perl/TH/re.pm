package Data::Sah::Compiler::perl::TH::re;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH';
with 'Data::Sah::Type::re';

# XXX prefilter to convert string to regex object

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = "ref($dt) eq 'Regexp' || !ref($dt) && ".
        "eval { my \$_sahv_re = $dt; qr/\$_sahv_re/; 1 }";
}

1;
# ABSTRACT: perl's type handler for type "re"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
