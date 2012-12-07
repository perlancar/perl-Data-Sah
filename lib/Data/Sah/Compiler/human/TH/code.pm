package Data::Sah::Compiler::human::TH::code;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::code';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["code", "codes"],
        type  => 'noun',
    });
}

1;
# ABSTRACT: perl's type handler for type "code"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
