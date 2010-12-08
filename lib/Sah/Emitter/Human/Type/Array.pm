package Sah::Emitter::Human::Type::Array;
# ABSTRACT: Human-emitter for 'array' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Array';

sub attr_all_elements {
}

sub attr_elements {
}

sub attr_element_deps {
}

sub attr_elements_regex {
}

sub attr_max_len {
}

sub attr_len {
}

sub attr_min_len {
}

sub attr_some_of {
}

sub attr_unique {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
