package Data::Sah::Type::array;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause', 'has_clause_alias';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause 'elems',
    tags       => ['constraint'],
    arg        => ['array*' => {of=>'schema*'}],
    allow_expr => 0,
    attrs      => {
        create_default => {
            arg        => [bool => default=>1],
            allow_expr => 0, # TODO
        },
    },
    ;
has_clause_alias each_elem => 'of';

1;
# ABSTRACT: array type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
