package Data::Schema::Emitter::Perl::Type::Either;
# ABSTRACT: Perl-emitter for 'either' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Type::Either';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
