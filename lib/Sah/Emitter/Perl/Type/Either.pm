package Sah::Emitter::Perl::Type::Either;
# ABSTRACT: Perl-emitter for 'either' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Either';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
