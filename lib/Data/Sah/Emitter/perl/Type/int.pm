package Data::Sah::Emitter::perl::Type::int;
# ABSTRACT: Perl-emitter for int

use Any::Moose;
extends 'Data::Sah::Emitter::perl::Type::num';
with 'Data::Sah::Type::int';

sub clause_SANITY {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->emitter;
    my $t = $e->data_term;

    # exponential form? cache regex?
    {
        fs_expr =>
            "ref($t) || $t !~ /\\A[+-]?(?:\\d+(?:\.\\d*)?)\\z/ || ".
            "$t!=int($t)",
    };
};

sub clause_divisible_by {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->emitter;
    my $t = $e->data_term;
    my $v = $clause->{value_term};

    {
        sc_expr => "$t % $v == 0",
    }
}

sub clause_indivisible_by {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->emitter;
    my $t = $e->data_term;
    my $v = $clause->{value_term};

    {
        sc_expr => "$t % $v != 0",
    }
}

sub clause_mod {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->emitter;
    my $t = $e->data_term;
    my $v = $clause->{value_term};

    {
        sc_expr => "$t % ($v)->[0] == ($v)->[1]",
    };
}

no Any::Moose;
1;
