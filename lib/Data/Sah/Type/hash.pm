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
    arg        => ['hash' => {req=>1, values => ['sah::schema', {req=>1}, {}]}, {}],
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
    arg        => ['hash' => {
        req=>1,
        keys   => ['re', {req=>1}, {}],
        values => ['schema', {req=>1}, {}],
    }, {}],
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
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;
has_clause "allowed_keys",
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;
has_clause "allowed_keys_re",
    prio       => 51,
    tags       => ['constraint'],
    arg        => ['re', {req=>1}, {}],
    allow_expr => 1,
    ;
has_clause "forbidden_keys",
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}]}, {}],
    allow_expr => 1,
    ;
has_clause "forbidden_keys_re",
    prio       => 51,
    tags       => ['constraint'],
    arg        => ['re', {req=>1}, {}],
    allow_expr => 1,
    ;
has_clause_alias each_index => 'each_key';
has_clause_alias each_elem => 'each_value';
has_clause_alias check_each_index => 'check_each_key';
has_clause_alias check_each_elem => 'check_each_value';

has_clause "choose_one_key",
    prio       => 50,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_one_key => 'choose_one';
has_clause "choose_all_keys",
    prio       => 50,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias choose_all_keys => 'choose_all';
has_clause "req_one_key",
    prio       => 50,
    tags       => ['constraint'],
    arg        => ['array', {req=>1, of=>['str', {req=>1}, {}], min_len=>1}, {}],
    allow_expr => 0, # for now
    ;
has_clause_alias req_one_key => 'req_one';
has_clause_alias req_keys => 'req_all_keys';
has_clause_alias req_keys => 'req_all';

# for now we only support the first argument as str, not array[str]
#my $dep_arg = ['array*', {elems=>[ ['any*', of=>['str*', ['array*',{of=>'str*'}]]], ['array*',of=>'str*'] ]}];
my $dep_arg = ['array', {
    req => 1,
    elems => [
        ['str', {req=>1}, {}],
        ['array', {of=>['str', {req=>1}, {}]}, {}],
    ],
}, {}];

has_clause "dep_any",
    prio       => 50,
    tags       => ['constraint'],
    arg        => $dep_arg,
    allow_expr => 0, # for now
    ;
has_clause "dep_all",
    prio       => 50,
    tags       => ['constraint'],
    arg        => $dep_arg,
    allow_expr => 0, # for now
    ;
has_clause "req_dep_any",
    prio       => 50,
    tags       => ['constraint'],
    arg        => $dep_arg,
    allow_expr => 0, # for now
    ;
has_clause "req_dep_all",
    prio       => 50,
    tags       => ['constraint'],
    arg        => $dep_arg,
    allow_expr => 0, # for now
    ;

# prop_alias indices => 'keys'

# prop_alias elems => 'values'

1;
# ABSTRACT: hash type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
