package Sah::Emitter::Base::Type::Base;
# ABSTRACT: Base class for type emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
