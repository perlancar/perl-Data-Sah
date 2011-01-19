package Data::Sah::Compiler::Perl::TH::obj;
# ABSTRACT: Perl type handler for type 'obj'

use Any::Moose;
extends 'Data::Sah::Compiler::Perl::TH::BaseperlTH';
with 'Data::Sah::Type::obj';

after clause_SANITY => sub {
    my ($self, %args) = @_;
    my $clause = $args{clause};
    my $e = $self->compiler;

    $e->errif($clause, '!Scalar::Util::blessed($data)', 'last ATTRS');
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

no Any::Moose;
1;
