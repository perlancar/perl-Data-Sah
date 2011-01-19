package Data::Sah::Compiler::Human::TH::CIStr;
# ABSTRACT: Human-emitter for 'cistr' type

use Any::Moose;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::CIStr';

sub clause_all_elements {
}

sub clause_elements {
}

sub clause_element_deps {
}

sub clause_elements_regex {
}

sub clause_max_len {
}

sub clause_len {
}

sub clause_min_len {
}

sub clause_not_match {
}

sub clause_match {
}

sub clause_isa_regex {
}

no Any::Moose;
1;
