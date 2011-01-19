package Data::Sah::Compiler::human::TH::all;
# ABSTRACT: Human-compiler type handler for type 'all'

use Any::Moose;
extends 'Sah::Compiler::human::TH::BasehumanTH';
with 'Sah::Type::all';

sub clause_of {
}

no Any::Moose;
1;
