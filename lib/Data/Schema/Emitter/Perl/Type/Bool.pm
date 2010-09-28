package Data::Schema::Emitter::Perl::Type::Bool;
# ABSTRACT: Perl-emitter for 'bool' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Base';
with 'Data::Schema::Spec::v10::Type::Bool';

sub eq {
    my ($self, %args) = @_;
    my $e = $self->emitter;
    "(((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") ? 1:0) == ".
     "((" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . ") ? 1:0))";
}

sub cmp {
    my ($self, %args) = @_;
    my $e = $self->emitter;
    "(((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") ? 1:0) <=> ".
     "((" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . ") ? 1:0))";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
