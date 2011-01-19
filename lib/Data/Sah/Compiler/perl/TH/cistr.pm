package Data::Sah::Compiler::perl::TH::cistr;
# ABSTRACT: Perl type handler for type 'cistr'

use Any::Moose;
extends 'Data::Sah::Compiler::perl::TH::str';
with 'Data::Sah::Type::cistr';

#TEMP, should already be defined by str
sub clause_match_all {}
sub clause_match_one {}

no Any::Moose;
1;
