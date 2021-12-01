package Data::Sah::Type::bool;

use strict;

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

has_clause 'is_true',
    v => 2,
    tags       => ['constraint'],
    schema     => ['bool', {}],
    allow_expr => 1,
    ;

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: bool type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
