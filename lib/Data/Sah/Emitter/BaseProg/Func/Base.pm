package Data::Sah::Emitter::ProgBase::Func::Base;
# ABSTRACT: Base class for programming language func-emitters

use Any::Moose;
extends 'Sah::Emitter::Base::Func::Base';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
