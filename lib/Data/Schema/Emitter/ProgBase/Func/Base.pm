package Data::Schema::Emitter::ProgBase::Func::Base;
# ABSTRACT: Base class for programming language func-emitters

use Any::Moose;
extends 'Data::Schema::Emitter::Base::Func::Base';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
