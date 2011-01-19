package Data::Sah::Compiler::perl::TH::bool;
# ABSTRACT: Perl type handler for type 'bool'

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::bool';

sub eq {
    my ($self, %args) = @_;
    my $e = $self->compiler;
    "(((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") ? 1:0) == ".
     "((" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . ") ? 1:0))";
}

sub cmp {
    my ($self, %args) = @_;
    my $e = $self->compiler;
    "(((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") ? 1:0) <=> ".
     "((" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . ") ? 1:0))";
}

# XXX do we allow refs etc to be valid true values?
#after clause_SANITY => sub {};

no Any::Moose;
1;
