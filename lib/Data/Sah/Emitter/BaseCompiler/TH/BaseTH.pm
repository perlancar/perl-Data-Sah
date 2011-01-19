package Data::Sah::Emitter::BaseEmitter::Type::BaseTH;
# ABSTRACT: Base class for type handlers

use Any::Moose;

has 'emitter' => (is => 'rw');

no Any::Moose;
1;
