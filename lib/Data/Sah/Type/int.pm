package Data::Sah::Type::int;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::num';

# VERSION

has_clause 'mod',
    prio=>50, tags=>['constraint'],
    arg => ['array*' => {elems => [['int*' => {'!is'=>0}], 'int*']}];

has_clause 'div_by',
    prio=>50, tags=>['constraint'],
    arg => ['int*' => {'!is'=>0}];

1;
# ABSTRACT: int type

=cut
