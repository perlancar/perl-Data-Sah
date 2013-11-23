package Data::Sah::Compiler::js::TH::buf;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH::str';
with 'Data::Sah::Type::buf';

# VERSION

1;
# ABSTRACT: js's type handler for type "buf"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$
