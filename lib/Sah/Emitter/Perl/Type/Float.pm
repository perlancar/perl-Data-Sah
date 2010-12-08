package Sah::Emitter::Perl::Type::Float;
# ABSTRACT: Perl-emitter for 'float' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Num';
with 'Sah::Spec::v10::Type::Float';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
