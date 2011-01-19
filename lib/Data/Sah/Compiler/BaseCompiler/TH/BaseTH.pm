package Data::Sah::Compiler::BaseCompiler::TH::BaseTH;
# ABSTRACT: Base class for type handlers

use Any::Moose;

has compiler => (is => 'rw');

no Any::Moose;
1;
