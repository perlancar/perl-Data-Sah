package Data::Sah::Compiler::js::TH::all;

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
#    'Data::Sah::Compiler::js::TH',
#    'Data::Sah::Compiler::Prog::TH::all';

use parent (
    'Data::Sah::Compiler::js::TH',
    'Data::Sah::Compiler::Prog::TH::all',
);

1;
# ABSTRACT: js's type handler for type "all"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
