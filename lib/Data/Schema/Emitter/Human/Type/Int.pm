package Data::Schema::Emitter::Human::Type::Int;
# ABSTRACT: Human-emitter for 'int' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Num';
with 'Data::Schema::Type::Int';

sub attr_mod {
}

sub attr_divisible_by {
}

sub attr_not_divisible_by {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
