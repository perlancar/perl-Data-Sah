package Data::Sah::Type::hash;

use Moo::Role;
use Data::Sah::Util 'has_clause', 'clause_alias';
with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::HasElems';

# VERSION

has_clause 'keys', arg => ['hash*' => {each_value => 'schema*'}], allow_expr=>0, attrs=>{restrict=>{arg=>[bool=>{default=>1}]}};

clause_alias each_index => 'each_key';
clause_alias each => 'each_value';

1;
# ABSTRACT: hash type
