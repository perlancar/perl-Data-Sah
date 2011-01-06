package Data::Sah::Emitter::Human::Type::Int;
# ABSTRACT: Human-emitter for 'int' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Num';
with 'Sah::Type::Int';

sub clause_mod {
}

sub clause_divisible_by {
}

sub clause_not_divisible_by {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
