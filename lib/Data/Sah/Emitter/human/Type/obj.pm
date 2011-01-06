package Data::Sah::Emitter::Human::Type::Object;
# ABSTRACT: Human-emitter for 'obj' type

use Any::Moose;
extends 'Sah::Emitter::Human::Type::Base';
with 'Sah::Type::Object';

sub clause_can_all {
}

sub clause_can_one {
}

sub clause_cannot {
}

sub clause_isa_all {
}

sub clause_isa_one {
}

sub clause_not_isa {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
