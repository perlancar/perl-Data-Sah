package Data::Sah::Emitter::Human::Type::CIStr;
# ABSTRACT: Human-emitter for 'cistr' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::CIStr';

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

sub attr_not_match {
}

sub attr_match {
}

sub attr_isa_regex {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
