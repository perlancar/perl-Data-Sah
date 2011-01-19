package Data::Sah::Compiler::Human::TH::Array;
# ABSTRACT: Human-emitter for 'array' type

use Any::Moose;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::Array';

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

sub clause_some_of {
}

sub clause_unique {
}

no Any::Moose;
1;
