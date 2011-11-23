package Data::Sah::Compiler::Human::TH::Object;
# ABSTRACT: Human-emitter for 'obj' type

use Moo;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::Object';

sub clause_can_all {
}

sub clause_can_one {
}

sub clause_cannot {
}

sub clause_isa_all {
}

sub clause_isa_one {
}

sub clause_not_isa {
}

1;
