package Data::Sah::Compiler::perl::TH::datetime;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::date';
with 'Data::Sah::Type::datetime';

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: perl's type handler for type "datetime"

=for Pod::Coverage ^(clause_.+|superclause_.+|handle_.+|before_.+|after_.+)$

=cut
