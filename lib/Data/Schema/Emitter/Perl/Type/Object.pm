package Data::Schema::Emitter::Perl::Type::Object;
# ABSTRACT: Perl-emitter for 'obj' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::Object';

sub attr_can_all {
}

sub attr_can_one {
}

sub attr_cannot {
}

sub attr_isa_all {
}

sub attr_isa_one {
}

sub attr_not_isa {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
