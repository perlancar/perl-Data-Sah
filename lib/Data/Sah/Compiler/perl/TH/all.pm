package Data::Sah::Compiler::perl::TH::all;

use 5.010;
use Log::Any '$log';
use Moo;
extends
    'Data::Sah::Compiler::perl::TH',
    'Data::Sah::Compiler::Prog::TH::all';

# VERSION

1;
# ABSTRACT: perl's type handler for type "all"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
