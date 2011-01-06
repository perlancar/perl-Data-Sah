package Data::Sah::Emitter::Perl::Type::Object;
# ABSTRACT: Perl-emitter for 'obj' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';
with 'Sah::Spec::v10::Type::Object';

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '!Scalar::Util::blessed($data)', 'last ATTRS');
};

sub clause_can_all {
}

sub clause_can_one {
}

sub clause_cannot {
}

sub clause_isa_all {
}

sub clause_isa_one {
}

sub clause_not_isa {
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
