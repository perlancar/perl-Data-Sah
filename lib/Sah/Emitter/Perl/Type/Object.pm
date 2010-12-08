package Sah::Emitter::Perl::Type::Object;
# ABSTRACT: Perl-emitter for 'obj' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Object';

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '!Scalar::Util::blessed($data)', 'last ATTRS');
};

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
