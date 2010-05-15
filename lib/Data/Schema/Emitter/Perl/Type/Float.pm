package Data::Schema::Emitter::Perl::Type::Float;
# ABSTRACT: Perl-emitter for 'float' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Num';
with 'Data::Schema::Type::Float';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
