package Data::Sah::Emitter::BaseEmitter::Func::BaseFunc;
# ABSTRACT: Base class for func emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
