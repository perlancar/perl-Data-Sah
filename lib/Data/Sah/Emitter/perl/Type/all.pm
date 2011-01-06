package Data::Sah::Emitter::Perl::Type::All;
# ABSTRACT: Perl-emitter for 'all' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::All';

sub clause_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
