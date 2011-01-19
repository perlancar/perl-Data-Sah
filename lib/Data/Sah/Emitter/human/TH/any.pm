package Data::Sah::Compiler::human::TH::either;
# ABSTRACT: Human-compiler type handler for type 'either'

use Any::Moose;
extends 'Sah::Compiler::human::TH::BasehumanTH';
with 'Sah::Type::either';

sub clause_of {
}

no Any::Moose;
1;
