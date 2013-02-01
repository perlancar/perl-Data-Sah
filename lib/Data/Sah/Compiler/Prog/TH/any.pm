package Data::Sah::Compiler::Prog::TH::any;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::js::TH';
with 'Data::Sah::Type::any';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    $cd->{_ccl_check_type} = $c->true;
}

sub clause_of {
    my ($self, $cd) = @_;
    $self->gen_any_or_all_of("any", $cd);
}

1;
# ABSTRACT: Base class for programming language compiler handler for type "any"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
