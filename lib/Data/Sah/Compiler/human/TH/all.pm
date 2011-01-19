package Data::Sah::Compiler::human::TH::all;
# ABSTRACT: Human-compiler type handler for type 'all'

use Any::Moose;
extends 'Data::SahCompiler::human::TH::BasehumanTH';
with 'Data::SahTH::all';

sub clause_of {
}

no Any::Moose;
1;
