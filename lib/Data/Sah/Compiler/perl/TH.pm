package Data::Sah::Compiler::perl::TH;

use Moo;
extends 'Data::Sah::Compiler::BaseProg::TH';

# VERSION

sub clause_default {}
sub clause_ok {}
sub clause_min_ok {}
sub clause_max_ok {}
sub clause_min_nok {}
sub clause_max_nok {}
sub clause_req {}
sub clause_forbidden {}

1;
# ABSTRACT: Base class for perl type handlers
