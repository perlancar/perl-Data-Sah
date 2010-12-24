package Data::Sah::Emitter::Human::Type::Num;
# ABSTRACT: Base class for Human-emitter for numeric types

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';

sub eq {
}

sub cmp {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
