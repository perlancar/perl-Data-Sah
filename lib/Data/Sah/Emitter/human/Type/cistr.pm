package Data::Sah::Emitter::Human::Type::CIStr;
# ABSTRACT: Human-emitter for 'cistr' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::CIStr';

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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
