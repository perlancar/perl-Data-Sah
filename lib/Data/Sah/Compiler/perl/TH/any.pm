package Data::Sah::Compiler::perl::TH::any;

use 5.010;
use Log::Any '$log';
use Moo;
extends
    'Data::Sah::Compiler::perl::TH',
    'Data::Sah::Compiler::Prog::TH::any';

# VERSION

1;
# ABSTRACT: perl's type handler for type "any"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
