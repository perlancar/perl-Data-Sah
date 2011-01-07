package Data::Sah::Emitter::Perl::Type::Num;
# ABSTRACT: Base class for Perl-emitter for numeric types

use Any::Moose;
extends 'Sah::Emitter::Perl::Type::Base';

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

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->emitter;

    $e->errif($clause, '!Scalar::Util::looks_like_number($data)', 'last ATTRS');
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
