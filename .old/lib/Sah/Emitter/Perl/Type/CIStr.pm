package Data::Schema::Emitter::Perl::Type::CIStr;
# ABSTRACT: Perl-emitter for 'cistr' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Str';
with 'Data::Schema::Spec::v10::Type::CIStr';

#TEMP, should already be defined by Str
sub attr_match_all {}
sub attr_match_one {}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
