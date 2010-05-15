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

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
