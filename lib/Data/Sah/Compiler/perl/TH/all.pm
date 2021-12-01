package Data::Sah::Compiler::perl::TH::all;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

# Mo currently doesn't support multiple classes in 'extends'
#extends
#    'Data::Sah::Compiler::perl::TH',
#    'Data::Sah::Compiler::Prog::TH::all';

use parent (
    'Data::Sah::Compiler::perl::TH',
    'Data::Sah::Compiler::Prog::TH::all',
);

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: perl's type handler for type "all"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
