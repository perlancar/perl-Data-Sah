package Data::Sah::Compiler::human::TH::re;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Type::re';

# VERSION

sub name { "regex pattern" }

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["regex pattern", "regex patterns"],
        type  => 'noun',
    });
}

1;
# ABSTRACT: perl's type handler for type "re"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
