package Data::Sah::Emitter::Perl::Type::CIStr;
# ABSTRACT: Perl-emitter for 'cistr' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Str';
with 'Sah::Spec::v10::Type::CIStr';

#TEMP, should already be defined by Str
sub attr_match_all {}
sub attr_match_one {}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
