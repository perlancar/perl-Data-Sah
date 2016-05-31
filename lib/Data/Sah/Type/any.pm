package Data::Sah::Type::any;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';

has_clause 'of',
    v => 2,
    tags       => ['constraint'],
    schema     => ['array' => {req=>1, min_len=>1, each_elem => ['sah::schema', {req=>1}, {}]}, {}],
    subschema  => sub { @{ $_[0] } },
    allow_expr => 0,
    ;

1;
# ABSTRACT: any type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
