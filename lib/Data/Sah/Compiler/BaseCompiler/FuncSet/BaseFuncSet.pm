package Data::Sah::Compiler::BaseCompiler::FuncSet::BaseFuncSet;
# ABSTRACT: Base class for function set handlers

use Any::Moose;

has compiler => (is => 'rw');

no Any::Moose;
1;
