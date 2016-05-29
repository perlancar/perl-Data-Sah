package Data::Sah::Type::obj;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';

has_clause 'can',
    v => 2,
    tags       => ['constraint'],
    arg        => ['str', {req => 1}, {}], # XXX perl_method_name
    allow_expr => 1,
    ;
has_clause 'isa',
    v => 2,
    tags       => ['constraint'],
    arg        => ['str', {req => 1}, {}], # XXX perl_class_name
    allow_expr => 1,
    ;

1;
# ABSTRACT: obj type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
