package Data::Sah::Compiler::human::TH;

use Moo;
extends 'Data::Sah::Compiler::TH';

# VERSION

# not translated

sub clause_prefilters {}
sub clause_postfilters {}

# usually handled in type handler's handle_type()

sub clause_default {}
sub clause_ok {}
sub clause_req {}
sub clause_forbidden {}

1;
# ABSTRACT: Base class for human type handlers
