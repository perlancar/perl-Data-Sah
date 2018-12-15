package Data::Sah::Compiler::perl::TH::datenotime;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::date';
with 'Data::Sah::Type::datenotime';

1;
# ABSTRACT: perl's type handler for type "datenotime"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=cut
