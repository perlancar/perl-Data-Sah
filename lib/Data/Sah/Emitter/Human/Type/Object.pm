package Data::Sah::Emitter::Human::Type::Object;
# ABSTRACT: Human-emitter for 'obj' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Object';

sub attr_can_all {
}

sub attr_can_one {
}

sub attr_cannot {
}

sub attr_isa_all {
}

sub attr_isa_one {
}

sub attr_not_isa {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
