package Data::Sah::Compiler::js::TH::buf;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::js::TH::str';
with 'Data::Sah::Type::buf';

1;
# ABSTRACT: js's type handler for type "buf"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$
