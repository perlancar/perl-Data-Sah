package Data::Sah::Compiler::perl::TH::buf;

use 5.010;
use Log::Any '$log';
use Moo;
use experimental 'smartmatch';
extends 'Data::Sah::Compiler::perl::TH::str';
with 'Data::Sah::Type::buf';

# VERSION

1;
# ABSTRACT: perl's type handler for type "buf"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
