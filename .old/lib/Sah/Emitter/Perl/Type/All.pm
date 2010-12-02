package Data::Schema::Emitter::Perl::Type::All;
# ABSTRACT: Perl-emitter for 'all' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::All';

sub attr_of {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
