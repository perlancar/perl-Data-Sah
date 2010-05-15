package Data::Schema::Emitter::Human::Type::All;
# ABSTRACT: Human-emitter for 'all' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Base';
with 'Data::Schema::Type::All';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
