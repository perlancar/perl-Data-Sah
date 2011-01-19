package Data::Sah::Compiler::human::TH::either;
# ABSTRACT: Human-compiler type handler for type 'either'

use Any::Moose;
extends 'Data::SahCompiler::human::TH::BasehumanTH';
with 'Data::SahTH::either';

sub clause_of {
}

no Any::Moose;
1;
