package Data::Sah::Compiler::human::TH::datetime;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::human::TH::date';

sub name { "datetime" }

1;
# ABSTRACT: perl's type handler for type "datetime"

=for Pod::Coverage ^(name|clause_.+|superclause_.+|before_.+|after_.+)$
