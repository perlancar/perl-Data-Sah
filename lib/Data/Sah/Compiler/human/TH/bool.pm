package Data::Sah::Compiler::Human::TH::Bool;
# ABSTRACT: Human-emitter for 'bool' type

use Any::Moose;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::Bool';

sub eq {
}

sub cmp {
}

no Any::Moose;
1;
