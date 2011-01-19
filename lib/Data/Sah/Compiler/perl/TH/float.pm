package Data::Sah::Compiler::perl::TH::float;
# ABSTRACT: Perl type handler for type 'float'

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::float';

no Any::Moose;
1;
