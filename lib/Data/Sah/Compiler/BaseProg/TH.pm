package Data::Sah::Compiler::BaseProg::TH;

use Moo;
extends 'Data::Sah::Compiler::BaseCompiler::TH';

sub clause_name {}
sub clause_summary {}
sub clause_description {}
sub clause_comment {}
sub clause_tags {}

1;
# ABSTRACT: Base class for programming-language emiting compiler's type handlers

=cut
