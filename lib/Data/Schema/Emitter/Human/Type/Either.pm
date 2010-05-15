package Data::Schema::Emitter::Human::Type::Either;
# ABSTRACT: Human-emitter for 'either' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Base';
with 'Data::Schema::Type::Either';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
