package Data::Sah::Type::hash;

use Moo::Role;
use Data::Sah::Util 'has_clause', 'clause_alias';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

# VERSION

#has_clause 'elems', arg => ['array*' => {of=>'schema*'}];
clause_alias each_elem => 'of';

has_clause "keys",
    tags       => ['constraint'],
    arg        => ['hash*' => {values => 'schema*'}],
    allow_expr => 0,
    attrs      => {
        restrict => {
            arg        => [bool => default=>1],
            allow_expr => 0,
        },
    },
    ;
has_clause "re_keys",
    tags       => ['constraint'],
    arg        => ['hash*' => {keys => 're*', values => 'schema*'}],
    allow_expr => 0,
    attrs      => {
        restrict => {
            arg        => [bool => default=>1],
            allow_expr => 0,
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
    tags       => ['constraint'],
    arg        => 're*',
    allow_expr => 1,
    ;
clause_alias each_index => 'each_key';
clause_alias each_elem => 'each_value';
clause_alias check_each_index => 'check_each_key';
clause_alias check_each_elem => 'check_each_value';

# prop_alias indices => 'keys'

# prop_alias elems => 'values'

1;
# ABSTRACT: hash type
