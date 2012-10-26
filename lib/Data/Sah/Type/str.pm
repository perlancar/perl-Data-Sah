package Data::Sah::Type::str;

use Moo::Role;
use Data::Sah::Util 'has_clause';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';
with 'Data::Sah::Type::HasElems';

# VERSION

my $t_re = 'regex*|{*=>regex*}';

has_clause 'match',
    tags       => ['constraint'],
    arg        => $t_re,
    allow_expr => 1,
    ;
has_clause 'is_re',
    tags       => ['constraint'],
    arg        => 'bool',
    allow_expr => 1,
    ;

1;
# ABSTRACT: str type

=cut
