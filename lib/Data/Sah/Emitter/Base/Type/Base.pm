package Data::Sah::Emitter::Base::Type::Base;
# ABSTRACT: Base class for type emitters

use Any::Moose;

has 'emitter' => (is => 'rw');

no Any::Moose;
1;
