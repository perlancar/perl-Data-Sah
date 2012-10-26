package Data::Sah::Compiler::Prog::TH;

use Moo;
extends 'Data::Sah::Compiler::TH';

# VERSION

sub clause_name {}
sub clause_summary {}
sub clause_description {}
sub clause_comment {}
sub clause_tags {}

# handled in a common routine
sub clause_default {}
sub clause_req {}
sub clause_forbidden {}

1;
# ABSTRACT: Base class for programming-language emiting compiler's type handlers

=cut
