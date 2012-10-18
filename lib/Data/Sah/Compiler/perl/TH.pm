package Data::Sah::Compiler::perl::TH;

use Moo;
extends 'Data::Sah::Compiler::BaseProg::TH';

# VERSION

# handled in compiler's before_all_clauses()

sub clause_default {}
sub clause_ok {}
sub clause_req {}
sub clause_forbidden {}
sub clause_prefilters {}

# handled in compiler's after_all_clauses()
#sub clause_postfilters {}

1;
# ABSTRACT: Base class for perl type handlers
