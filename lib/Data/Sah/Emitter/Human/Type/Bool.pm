package Data::Sah::Emitter::Human::Type::Bool;
# ABSTRACT: Human-emitter for 'bool' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Bool';

sub eq {
}

sub cmp {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
