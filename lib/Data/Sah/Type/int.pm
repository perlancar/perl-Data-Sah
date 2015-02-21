package Data::Sah::Type::int;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::num';

has_clause 'mod',
    tags       => ['constraint'],
    arg        => ['array*' => {elems => [['int*' => {'!is'=>0}], 'int*']}],
    allow_expr => 1,
    ;
has_clause 'div_by',
    tags       => ['constraint'],
    arg        => ['int*' => {'!is'=>0}],
    allow_expr => 1,
    ;

1;
# ABSTRACT: int type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
