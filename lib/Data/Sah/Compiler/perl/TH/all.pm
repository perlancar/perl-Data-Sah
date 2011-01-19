package Data::Sah::Compiler::perl::TH::all;
# ABSTRACT: Perl type handler for 'all' type

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::all';

sub clause_of {
}

no Any::Moose;
1;
