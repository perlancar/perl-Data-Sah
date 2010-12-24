package Data::Sah::Emitter::Human::Type::All;
# ABSTRACT: Human-emitter for 'all' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::All';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
