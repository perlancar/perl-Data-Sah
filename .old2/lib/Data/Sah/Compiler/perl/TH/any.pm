package Data::Sah::Compiler::perl::TH::any;
# ABSTRACT: Perl type handler for type 'any'

use Moo;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::any';

sub clause_of {
}

1;
