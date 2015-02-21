package Data::Sah::Compiler::js::TH::any;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
#use Role::Tiny::With;

# Mo currently doesn't support multiple classes in 'extends'
#extends
#    'Data::Sah::Compiler::js::TH',
#    'Data::Sah::Compiler::Prog::TH::any';

use parent (
    'Data::Sah::Compiler::js::TH',
    'Data::Sah::Compiler::Prog::TH::any',
);

1;
# ABSTRACT: js's type handler for type "any"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
