package Data::Schema::Emitter::Perl::Type::DateTime;
# ABSTRACT: Perl-emitter for 'datetime' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::DateTime';

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
