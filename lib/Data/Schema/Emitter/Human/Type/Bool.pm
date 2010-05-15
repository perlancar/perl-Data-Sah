package Data::Schema::Emitter::Human::Type::Bool;
# ABSTRACT: Human-emitter for 'bool' type

use Any::Moose;
extends 'Data::Schema::Emitter::Human::Type::Base';
with 'Data::Schema::Type::Bool';

sub eq {
}

sub cmp {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
