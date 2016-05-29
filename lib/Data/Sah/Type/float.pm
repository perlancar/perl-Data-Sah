package Data::Sah::Type::float;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::num';

has_clause 'is_nan',
    v => 2,
    tags        => ['constraint'],
    arg         => ['bool', {}, {}],
    allow_expr  => 1,
    allow_multi => 0,
    ;

has_clause 'is_inf',
    v => 2,
    tags        => ['constraint'],
    arg         => ['bool', {}, {}],
    allow_expr  => 1,
    allow_multi => 1,
    ;

has_clause 'is_pos_inf',
    v => 2,
    tags        => ['constraint'],
    arg         => ['bool', {}, {}],
    allow_expr  => 1,
    allow_multi => 1,
    ;

has_clause 'is_neg_inf',
    v => 2,
    tags        => ['constraint'],
    arg         => ['bool', {}, {}],
    allow_expr  => 1,
    allow_multi => 1,
    ;

1;
# ABSTRACT: float type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
