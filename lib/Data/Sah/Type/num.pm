package Data::Sah::Type::num;

# AUTHORITY
# DATE
# DIST
# VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

1;
# ABSTRACT: num type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
