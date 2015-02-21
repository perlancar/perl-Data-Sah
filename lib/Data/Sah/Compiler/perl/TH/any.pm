package Data::Sah::Compiler::perl::TH::any;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

# Mo currently doesn't support multiple classes in 'extends'
#extends
#    'Data::Sah::Compiler::perl::TH',
#    'Data::Sah::Compiler::Prog::TH::any';

use parent (
    'Data::Sah::Compiler::perl::TH',
    'Data::Sah::Compiler::Prog::TH::any',
);

1;
# ABSTRACT: perl's type handler for type "any"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
