package Data::Sah::Type::str;

# DATE
# VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';
with 'Data::Sah::Type::HasElems';

# currently we only support regex instead of hash of regexes
#my $t_re = 'regex*|{*=>regex*}';
my $t_re = ['regex', {req=>1}, {}];

has_clause 'encoding',
    v => 2,
    tags       => ['constraint'],
    schema     => ['str', {req=>1}, {}],
    allow_expr => 0,
    ;
has_clause 'match',
    v => 2,
    tags       => ['constraint'],
    schema     => $t_re,
    allow_expr => 1,
    ;
has_clause 'is_re',
    v => 2,
    tags       => ['constraint'],
    schema     => ['bool', {}, {}],
    allow_expr => 1,
    ;

1;
# ABSTRACT: str type

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$
