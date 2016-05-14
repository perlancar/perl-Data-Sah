package Data::Sah::Type::int;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::num';

has_clause 'mod',
    tags       => ['constraint'],
    arg        => ['array' => {req=>1, len=>2, elems => [
        ['int' => {req=>1, is=>0, 'is.op'=>'not'}, {}],
        ['int' => {req=>1}, {}],
    ]}, {}],
    allow_expr => 1,
    ;
has_clause 'div_by',
    tags       => ['constraint'],
    arg        => ['int' => {req=>1, is=>0, 'is.op'=>'not'}, {}],
    allow_expr => 1,
    ;

1;
# ABSTRACT: int type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
