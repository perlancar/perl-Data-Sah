package Data::Sah::Emitter::Human::Type::Either;
# ABSTRACT: Human-emitter for 'either' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Either';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
