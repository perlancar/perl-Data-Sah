package Data::Sah::Compiler::Perl::TH::num;
# ABSTRACT: Base class for Perl-emitter for numeric types

use Moo;
##extends 'Data::Sah::Compiler::Perl::TH::BaseperlTH';
##with 'Data::Sah::Type::num';

# VERSION

sub eq {
    my ($self, %args) = @_;
    my $e = $self->compiler;
    "((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") == ".
     "(" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . "))";
}

sub cmp {
    my ($self, %args) = @_;
    my $e = $self->compiler;
    "((" . ($args{va} ? $args{va} : $e->dump($args{a})) . ") <=> ".
     "(" . ($args{vb} ? $args{vb} : $e->dump($args{b})) . "))";
}

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, '!Scalar::Util::looks_like_number($data)', 'last ATTRS');
};

1;
