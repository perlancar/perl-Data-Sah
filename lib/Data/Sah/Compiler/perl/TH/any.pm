package Data::Sah::Compiler::perl::TH::any;
# ABSTRACT: Perl type handler for type 'any'

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::any';

sub clause_of {
}

no Any::Moose;
1;
