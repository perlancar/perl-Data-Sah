package Data::Sah::Emitter::ProgBase::Type::Base;
# ABSTRACT: Base class for programming language type-emitters

use Any::Moose;
extends 'Sah::Emitter::Base::Type::Base';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
