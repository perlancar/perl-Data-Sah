package Data::Sah::Type::array;

use Moo::Role;
use Data::Sah::Util 'has_clause', 'clause_alias';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

has_clause 'elems', arg => ['array*' => {of=>'schema*'}];
clause_alias each => 'of';

1;
# ABSTRACT: array type
