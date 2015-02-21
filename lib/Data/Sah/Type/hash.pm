package Data::Sah::Type::hash;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause', 'has_clause_alias';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause_alias each_elem => 'of';

has_clause "keys",
    tags       => ['constraint'],
    arg        => ['hash*' => {values => 'schema*'}],
    allow_expr => 0,
    attrs      => {
        restrict => {
            arg        => [bool => default=>1],
            allow_expr => 0, # TODO
        },
        create_default => {
            arg        => [bool => default=>1],
            allow_expr => 0, # TODO
        },
    },
    ;
has_clause "re_keys",
    prio       => 51,
    tags       => ['constraint'],
    arg        => ['hash*' => {keys => 're*', values => 'schema*'}],
    allow_expr => 0,
    attrs      => {
        restrict => {
            arg        => [bool => default=>1],
            allow_expr => 0, # TODO
        },
    },
    ;
has_clause "req_keys",
    tags       => ['constraint'],
    arg        => ['array*'],
    allow_expr => 1,
    ;
has_clause "allowed_keys",
    tags       => ['constraint'],
    arg        => ['array*'],
    allow_expr => 1,
    ;
has_clause "allowed_keys_re",
    prio       => 51,
    tags       => ['constraint'],
    arg        => 're*',
    allow_expr => 1,
    ;
has_clause "forbidden_keys",
    tags       => ['constraint'],
    arg        => ['array*'],
    allow_expr => 1,
    ;
has_clause "forbidden_keys_re",
    prio       => 51,
    tags       => ['constraint'],
    arg        => 're*',
    allow_expr => 1,
    ;
has_clause_alias each_index => 'each_key';
has_clause_alias each_elem => 'each_value';
has_clause_alias check_each_index => 'check_each_key';
has_clause_alias check_each_elem => 'check_each_value';

# prop_alias indices => 'keys'

# prop_alias elems => 'values'

1;
# ABSTRACT: hash type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
