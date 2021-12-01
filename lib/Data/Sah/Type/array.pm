package Data::Sah::Type::array;

use strict;

use Data::Sah::Util::Role 'has_clause', 'has_clause_alias';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause 'elems',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, of=>['sah::schema', {req=>1}, {}]}],
    inspect_elem => 1,
    allow_expr => 0,
    subschema  => sub { @{ $_[0] } },
    attrs      => {
        create_default => {
            schema     => [bool => {default=>1}],
            allow_expr => 0, # TODO
        },
    },
    ;
has_clause_alias each_elem => 'of';

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: array type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
