package Data::Sah::Compiler::TH;

use Moo;

# VERSION

# reference to compiler object
has compiler => (is => 'rw');

sub clause_v {}
sub clause_default_lang {}

1;
# ABSTRACT: Base class for type handlers

=cut
