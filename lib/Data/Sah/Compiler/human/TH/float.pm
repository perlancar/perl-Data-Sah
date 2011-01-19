package Data::Sah::Compiler::Human::TH::Float;
# ABSTRACT: Human-emitter for 'float' type

use Any::Moose;
extends 'Data::SahCompiler::Human::TH::Num';
with 'Data::SahTH::Float';

no Any::Moose;
1;
