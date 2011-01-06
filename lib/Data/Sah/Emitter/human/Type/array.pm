package Data::Sah::Emitter::Human::Type::Array;
# ABSTRACT: Human-emitter for 'array' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Array';

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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
