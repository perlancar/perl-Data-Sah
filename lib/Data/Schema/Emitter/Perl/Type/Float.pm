package Data::Schema::Emitter::Perl::Type::Float;
# ABSTRACT: Perl-emitter for 'float' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Num';
with 'Data::Schema::Spec::v10::Type::Float';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
