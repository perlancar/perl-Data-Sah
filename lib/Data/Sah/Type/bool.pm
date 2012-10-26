package Data::Sah::Type::bool;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# VERSION

has_clause 'is_true',
    tags       => ['constraint'],
    arg        => 'bool',
    allow_expr => 1,
    ;

1;
# ABSTRACT: bool type

=cut
