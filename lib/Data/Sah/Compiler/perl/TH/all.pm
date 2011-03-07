package Data::Sah::Compiler::perl::TH::all;
# ABSTRACT: Perl type handler for 'all' type

use Moo;
extends 'Data::Sah::Compiler::perl::TH::BaseperlTH';
with 'Data::Sah::Type::all';

sub clause_of {
}

1;
