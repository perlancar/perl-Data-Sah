package Sah::Emitter::Human::Type::Float;
# ABSTRACT: Human-emitter for 'float' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Num';
with 'Sah::Type::Float';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
