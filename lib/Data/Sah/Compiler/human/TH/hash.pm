package Data::Sah::Compiler::Human::TH::Hash;
# ABSTRACT: Human-emitter for 'hash' type

use Any::Moose;
extends 'Data::SahCompiler::Human::TH::Base';
with 'Data::SahTH::Hash';

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

sub clause_allow_extra_keys {
}

sub clause_codependent_keys {
}

sub clause_codependent_keys_regex {
}

sub clause_conflicting_keys {
}

sub clause_conflicting_keys_regex {
}

sub clause_keys {
}

sub clause_keys_match {
}

sub clause_keys_not_match {
}

sub clause_keys_of {
}

sub clause_keys_one_of {
}

sub clause_keys_regex {
}

sub clause_required_keys {
}

sub clause_required_keys_regex {
}

sub clause_some_of {
}

sub clause_values_match {
}

sub clause_values_not_match {
}

sub clause_values_one_of {
}

no Any::Moose;
1;
