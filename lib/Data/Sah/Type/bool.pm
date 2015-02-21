package Data::Sah::Type::bool;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

has_clause 'is_true',
    tags       => ['constraint'],
    arg        => 'bool',
    allow_expr => 1,
    ;

1;
# ABSTRACT: bool type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

