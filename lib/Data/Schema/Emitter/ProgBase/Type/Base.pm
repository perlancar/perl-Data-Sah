package Data::Schema::Emitter::ProgBase::Type::Base;
# ABSTRACT: Base class for programming language type-emitters

use Any::Moose;
extends 'Data::Schema::Emitter::Base::Type::Base';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
