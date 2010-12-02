package Data::Schema::Emitter::Human::Type::Str;
# ABSTRACT: Human-emitter for 'string' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Base';
with 'Data::Schema::Type::Str';

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

sub attr_match {
}

sub attr_not_match {
}

sub attr_isa_regex {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
