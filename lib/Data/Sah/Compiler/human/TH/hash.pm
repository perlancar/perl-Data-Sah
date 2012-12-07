package Data::Sah::Compiler::human::TH::hash;

use 5.010;
use Log::Any '$log';
use Moo;
extends 'Data::Sah::Compiler::human::TH';
with 'Data::Sah::Compiler::human::TH::Comparable';
with 'Data::Sah::Compiler::human::TH::HasElems';
with 'Data::Sah::Type::hash';

# VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    $c->add_ccl($cd, {
        fmt   => ["hash", "hashes"],
        type  => 'noun',
    });
}

sub clause_keys { warn "NOT YET IMPLEMENTED" }
sub clause_re_keys { warn "NOT YET IMPLEMENTED" }
sub clause_req_keys { warn "NOT YET IMPLEMENTED" }
sub clause_allowed_keys { warn "NOT YET IMPLEMENTED" }
sub clause_allowed_keys_re { warn "NOT YET IMPLEMENTED" }

1;
# ABSTRACT: human's type handler for type "hash"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
