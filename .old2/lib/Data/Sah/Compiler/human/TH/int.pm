package Data::Sah::Compiler::Human::TH::Int;
# ABSTRACT: Human-emitter for 'int' type

use Moo;
extends 'Data::SahCompiler::Human::TH::Num';
with 'Data::SahTH::Int';

sub clause_mod {
}

sub clause_divisible_by {
}

sub clause_not_divisible_by {
}

1;
