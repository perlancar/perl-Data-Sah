package Data::Schema::Emitter::Human::Type::Float;
# ABSTRACT: Human-emitter for 'float' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Num';
with 'Data::Schema::Type::Float';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
