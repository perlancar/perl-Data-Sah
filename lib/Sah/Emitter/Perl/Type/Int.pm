package Sah::Emitter::Perl::Type::Int;
# ABSTRACT: Perl-emitter for 'int' type

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Num';
with 'Sah::Spec::v10::Type::Int';

after attr_SANITY => sub {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, 'int($data) != $data', 'last ATTRS');
};

sub attr_divisible_by {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '$data % '.$attr->{value}.' != 0');
}

sub attr_mod {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr,
              '$data % '.$attr->{value}.'->[0] != '.$attr->{value}.'->[1]');
}

sub attr_not_divisible_by {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '$data % '.$attr->{value}.' == 0');
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
