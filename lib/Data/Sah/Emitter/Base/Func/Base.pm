package Data::Sah::Emitter::Base::Func::Base;
# ABSTRACT: Base class for func emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
