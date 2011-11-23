package Data::Sah::Compiler::Human::TH::Bool;
# ABSTRACT: Human-emitter for 'bool' type

use Moo;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::Bool';

sub eq {
}

sub cmp {
}

1;
