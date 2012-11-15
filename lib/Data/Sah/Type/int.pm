package Data::Sah::Type::int;

use Moo::Role;
use Data::Sah::Util::Role 'has_clause';
with 'Data::Sah::Type::num';

# VERSION

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

=cut
