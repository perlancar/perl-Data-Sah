package Data::Schema::Emitter::Perl::Type::Num;
# ABSTRACT: Base class for Perl-emitter for numeric types

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';

sub eq {
    my ($self, %args) = @_;
    my $e = $self->emitter;
    "((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") == ".
     "(" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . "))";
}

sub cmp {
    my ($self, %args) = @_;
    my $e = $self->emitter;
    "((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") <=> ".
     "(" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . "))";
}

sub attr_SANITY {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;

    $e->errif($attr, '!Scalar::Util::looks_like_number($data)', 'last ATTRS');
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
