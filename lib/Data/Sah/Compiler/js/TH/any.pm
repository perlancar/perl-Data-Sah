package Data::Sah::Compiler::js::TH::any;

use 5.010;
use Log::Any '$log';
use Moo;
extends
    'Data::Sah::Compiler::js::TH',
    'Data::Sah::Compiler::Prog::TH::any';

# VERSION

1;
# ABSTRACT: js's type handler for type "any"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
