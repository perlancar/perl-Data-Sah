package Data::Sah::Compiler::human::TH::cistr;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH::str';

1;
# ABSTRACT: perl's type handler for type "cistr"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
