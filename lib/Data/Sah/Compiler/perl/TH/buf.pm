package Data::Sah::Compiler::perl::TH::buf;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::str';
with 'Data::Sah::Type::buf';

1;
# ABSTRACT: perl's type handler for type "buf"

=for Pod::Coverage ^(clause_.+|superclause_.+)$
