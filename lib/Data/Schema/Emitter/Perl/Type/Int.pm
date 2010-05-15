package Data::Schema::Emitter::Perl::Type::Int;
# ABSTRACT: Perl-emitter for 'int' type

use Any::Moose;
extends 'Data::Schema::Emitter::Perl::Type::Num';
with 'Data::Schema::Type::Int';

sub attr_mod {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    {err_cond => '$data % '.$attr->{value}[0].' != '.$attr->{value}[1]};
}

sub attr_divisible_by {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    {err_cond => '$data % '.$attr->{value}.' != 0'};
}

sub attr_not_divisible_by {
    my ($self, %args) = @_;
    my $attr = $args{attr};
    my $e = $self->emitter;
    {err_cond => '$data % '.$attr->{value}.' == 0'};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
